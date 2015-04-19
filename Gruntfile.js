/*______ _____ _____  _   _____________ _________________
  | ___ \  _  /  __ \| | / /_   _| ___ \  ___|  ___|  ___|
  | |_/ / | | | /  \/| |/ /  | | | |_/ / |__ | |_  | |_
  |    /| | | | |    |    \  | | |    /|  __||  _| |  _|
  | |\ \\ \_/ / \__/\| |\  \ | | | |\ \| |___| |   | |
  \_| \_|\___/ \____/\_| \_/ \_/ \_| \_\____/\_|   \_|
*/
;(function ( undefined ) { 'use strict';


var lrSnippet = require( 'grunt-contrib-livereload/lib/utils' ).livereloadSnippet
var mountFolder = function ( connect, dir ) {
	return connect.static( require( 'path' ).resolve( dir ) )
}


module.exports = function ( grunt ) {

	// load all grunt tasks
	require( 'matchdep' ).filterDev( 'grunt-*' ).forEach( grunt.loadNpmTasks )


	grunt.initConfig({
		pkg: grunt.file.readJSON( 'package.json' ),

		config: {
			source: './source',
			plugins: './plugins',
			conf: './_config.yml',
			tmp: './.tmp'
		},

		shell: {
			build: {
				command: 'jekyll build -s <%= config.source %> -d <%= config.tmp %> -p <%= config.plugins %> -c <%= config.conf %>'
			}
		},

		open: {
			server: {
				path: 'http://localhost:<%= connect.options.port %>'
			}
		},

		less: {
			site: {
				files: [
					{ src: '<%= config.source %>/styles/main.less', dest: '<%= config.tmp %>/styles/main.css' }
				]
			}
		},

		connect: {
			options: {
				port: 1337,
				hostname: '0.0.0.0'
			},
			livereload: {
				options: {
					middleware: function ( connect ) {
						return [
							connect.compress(),
							lrSnippet,
							mountFolder( connect, grunt.config.process( '<%= config.tmp %>' ) )
						]
					}
				}
			}
		},

		watch: {
			options: {
				interrupt: true,
				atBegin: true,
				livereload: true
			},
			less: {
				files: [ '<%= config.source %>/styles/**/*.less' ],
				tasks: [ 'less:site' ]
			},
			jekyll: {
				files: [
					'<%= config.source %>/_*/**/*.{markdown,md,html}',
					'<%= config.source %>/_config.yml',
					'<%= config.source %>/*.{markdown,md,html}'
				],
				tasks: [ 'shell:build', 'less:site' ]
			}
		}

	})




	grunt.registerTask( 'server', [
		'shell:build',
		'less:site',
		'connect:livereload',
		'open',
		'watch',
	])

	grunt.registerTask( 'default', [ 'server' ] )
}



}())
