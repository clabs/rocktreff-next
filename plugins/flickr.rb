require 'net/https'
require 'uri'
require 'json'

module Jekyll

class FlickrPhoto

    def initialize( json, size )
      @title          = json['title']
      @url            = json["url_#{size}"]
      @thumbnail_url  = json["url_t"]
    end

    def title
      return @title
    end

    def url
      return @url
    end

    def thumbnail_url
      return @thumbnail_url
    end

    def <=>( photo )
      @title <=> photo.title
    end

end



class FlickrPhotoset
    attr_accessor :id, :config, :cache_dir, :cache_file, :photos, :title

    def initialize( config, id )
        self.id = id
        self.cache_dir = 'plugins/flickr.cache'
        self.cache_file = "#{self.cache_dir}/#{self.id}.yml"
        self.photos = Array.new
        self.config = config
        # create cache directory
        if !Dir.exists?( self.cache_dir )
            Dir.mkdir( self.cache_dir )
        end

        if File.file?( self.cache_file )
            self.cache_load()
        else
            self.flickr_load()
        end
    end

    def flickr_load()
        print "\t\t    (Flickr) loading photoset #{self.id} from Flickr API\n"
        key = self.config[ 'api_key' ]
        uid = self.config[ 'user_id' ]
        thumbnail_size = self.config['image_size']
        # get json from flickr and parse photo items
        uri  = URI.parse("https://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&user_id=#{uid}&photoset_id=#{@id}&api_key=#{key}&format=json&nojsoncallback=1&extras=url_#{thumbnail_size},url_t")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        json = JSON.parse( http.request(Net::HTTP::Get.new(uri.request_uri)).body )
        self.title = json['photoset']['title']
        items = json['photoset']['photo']
        # populate photos
        @photos = Array.new
        items.each do |item|
            @photos << FlickrPhoto.new( item, thumbnail_size )
        end
        # write to cache
        self.cache_store
        # photos
    end

    def cache_load()
        cached = YAML::load( File.read( self.cache_file ) )
        self.id = cached['id']
        self.title = cached['title']
        self.photos = cached['photos']
        print "\t\t    (Flickr) loading photoset '#{self.title}' from cache\n"
    end

    def cache_store
        cached = Hash.new
        cached['id'] = self.id
        cached['title'] = self.title
        cached['photos'] = self.photos
        File.open( self.cache_file, 'w+' ) {|f| f.write(YAML::dump(cached))}
    end

end

class FlickrTag < Liquid::Tag

    def look_up( context, name )
      lookup = context
      name.split(".").each do |value|
        lookup = lookup[value]
      end
      lookup
    end

    def initialize (tag_name, markup, token)
      super
      @markup = markup
    end

    def render ( context )
      site = context.registers[:site]
      config = site.config[ 'flickr' ] || {}
      config['class']       ||= ''
      config['image_size']  ||= 'o'
      config['api_key']     ||= ''
      if @markup =~ /([\w]+(\.[\w]+)*)/i
        set = look_up(context, $1)
      else
        set = @markup
      end
      # populate photos
      photos = FlickrPhotoset.new( config, set ).photos

      html = "<div class=\"flickr gallery #{config['class']}\">"
      photos.each do |photo|
        html << "<a class=\"fancybox\" rel=\"group\" href=\"#{photo.url}\">"
        html << "  <img src=\"#{photo.thumbnail_url}\">"
        html << "</a>"
      end
      html << "</div>"
      return html
    end
end



end

Liquid::Template.register_tag( 'flickr', Jekyll::FlickrTag )
