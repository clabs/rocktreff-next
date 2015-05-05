require 'net/https'
require 'uri'
require 'json'

module Jekyll
  class FlickrTag < Liquid::Tag
    def look_up( context, name )
      lookup = context
      name.split(".").each do |value|
        lookup = lookup[value]
      end
      lookup
    end

    def initialize(tag_name, markup, token)
      super
      @markup = markup

      @config = Jekyll.configuration( {} )[ 'flickr' ] || {}

      @config['class']       ||= ''
      @config['a_href']      ||= 'c'
      @config['image_size']  ||= 'm'
      @config['api_key']     ||= ''
    end

    def render(context)
      if @markup =~ /([\w]+(\.[\w]+)*)/i
        @set = look_up(context, $1)
      end
      # uncomment to skip flickr api calls. TODO: integrate into dev mode
      #@html = ""
      #return @html
      # get json from flickr and parse photo items
      @uri  = URI.parse("https://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&photoset_id=#{@set}&api_key=#{@config['api_key']}&format=json&nojsoncallback=1")
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @json = @http.request(Net::HTTP::Get.new(@uri.request_uri)).body
      @items = JSON.parse(@json)['photoset']['photo']
      # populate photos
      @photos = Array.new
      @items.each do |item|
        @photos << FlickrPhoto.new(item['title'], item['id'], item['secret'], item['server'], item['farm'], @config['image_size'])
      end

      @html = "<div class=\"flickr gallery #{@config['class']}\">"
      @photos.each do |photo|
        @html << "<a class=\"fancybox\" rel=\"group\" href=\"#{photo.url(@config['a_href'])}\">"
        @html << "  <img src=\"#{photo.thumbnail_url}\">"
        @html << "</a>"
      end
      @html << "</div>"
      return @html
    end
  end

  class FlickrPhoto

    def initialize(title, id, secret, server, farm, thumbnail_size)
      @title          = title
      @url            = "http://farm#{farm}.staticflickr.com/#{server}/#{id}_#{secret}.jpg"
      @thumbnail_url  = url.gsub(/\.jpg/i, "_#{thumbnail_size}.jpg")
      @thumbnail_size = thumbnail_size
    end

    def title
      return @title
    end

    def url(size_override = nil)
      return (size_override ? @thumbnail_url.gsub(/_#{@thumbnail_size}.jpg/i, "_#{size_override}.jpg") : @url)
    end

    def thumbnail_url
      return @thumbnail_url
    end

    def <=>(photo)
      @title <=> photo.title
    end

  end

end

Liquid::Template.register_tag( 'flickr', Jekyll::FlickrTag )
