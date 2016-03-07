/*______ _____ _____  _   _____________ _________________
  | ___ \  _  /  __ \| | / /_   _| ___ \  ___|  ___|  ___|
  | |_/ / | | | /  \/| |/ /  | | | |_/ / |__ | |_  | |_
  |    /| | | | |    |    \  | | |    /|  __||  _| |  _|
  | |\ \\ \_/ / \__/\| |\  \ | | | |\ \| |___| |   | |
  \_| \_|\___/ \____/\_| \_/ \_/ \_| \_\____/\_|   \_|
*/
var mount = function ( connect, dir ) {
	return connect.static( require( 'path' ).resolve( dir ) )
}

module.exports = function ( grunt ) {
	grunt.initConfig({

		pkg: grunt.file.readJSON( 'package.json' ),


		config: {
			source: './source',
			plugins: './plugins',
			config: './config.yml',
			tmp: './.tmp'
		},


		connect: {
			options: {
				port: 1338,
				base: '<%= config.tmp %>',
				open: true
			},
			livereload: {
				options: {
					livereload: true
				}
			}
		},


		open: {
			server: {
				path: 'http://localhost:<%= connect.options.port %>'
			}
		},


		less: {
			development: {
				options: {
					compress: true,
					yuicompress: true,
					optimization: 2
				},
				files: {
					'<%= config.tmp %>/styles/main.css': '<%= config.source %>/styles/main.less'
				}
			}
		},

		postcss: {
			options: {
				map: false,
				processors: [
					require( 'pixrem' )(),
					require( 'autoprefixer' )({browsers: 'last 2 versions'}),
					require( 'cssnano' )()
				]
			},
			dist: {
				src: '<%= config.tmp %>/styles/*.css'
			}
		},

		imagemin: {
			dist: {
				options: {
					optimizationLevel: 5
				},
				files: [{
					expand: true,
					cwd: '<%= config.source %>/images',
					src: [ '**/*.{png,jpg,gif}' ],
					dest: '<%= config.tmp %>/images'
				}]
			}
		},


		jekyll: {
			options: {
				src: '<%= config.source %>',
				plugins: '<%= config.plugins %>',
				dest: '<%= config.tmp %>',
				config: '<%= config.config %>'
			},
			dev: {
				options: { incremental: true }
			},
			dist: {
				options: { }
			}
		},


		watch: {
			options: {
				livereload: true,
			},
			css: {
				files: [ '<%= config.source %>/styles/*' ],
				tasks: [ 'less', 'postcss' ]
			},
			images: {
				files: [ '<%= config.source %>/images/*' ],
				tasks: [ 'imagemin' ]
			},
			docs: {
				files: [
					'<%= config.source %>/**/*.{html,md,xml}',
					'!<%= config.source %>/vendor/**/*.{html,md,xml}'
				],
				tasks: [ 'jekyll:dev', 'less', 'postcss' ],
				options: { spawn: false }
			}
		},

		/*
		  _ _ ____  _ _ _  __
		 | '_(_-< || | ' \/ _|
		 |_| /__/\_, |_||_\__|
		         |__/
		*/
		rsync: {
			options: {
				args: [ '-avzce ssh', '--verbose', '--stats' ],
				exclude: [],
				recursive: true
			},
			webrelease: {
				options: {
					src: '<%= config.tmp %>/',
					dest: '/home/rocktreff/www/rocktreff.de/',
					host: 'rocktreff@rocktreff.de'
				}
			}
		}


	})

	require( 'load-grunt-tasks' )( grunt )

	grunt.registerTask( 'default', [ 'server' ] )
	grunt.registerTask( 'css', [ 'less', 'postcss' ] )
	grunt.registerTask( 'server', [ 'jekyll:dev', 'css', 'imagemin', 'connect', 'watch' ] )
	grunt.registerTask( 'deploy', [ 'jekyll:dist', 'css', 'imagemin', 'rsync' ] )

}







// ;(function ( undefined ) { 'use strict';


// var lrSnippet = require( 'grunt-contrib-livereload/lib/utils' ).livereloadSnippet
// var mountFolder = function ( connect, dir ) {
// 	return connect.static( require( 'path' ).resolve( dir ) )
// }


// module.exports = function ( grunt ) {

// 	// load all grunt tasks
// 	require( 'matchdep' ).filterDev( 'grunt-*' ).forEach( grunt.loadNpmTasks )


// 	grunt.initConfig({
// 		pkg: grunt.file.readJSON( 'package.json' ),

// 		config: {
// 			source: './source',
// 			plugins: './plugins',
// 			conf: './_config.yml',
// 			dist: './.dist'
// 		},



// 		less: {
// 			site: {
// 				files: [
// 					{ src: '<%= config.source %>/styles/main.less', dest: '<%= config.tmp %>/styles/main.css' }
// 				]
// 			}
// 		},

// 		connect: {
// 			options: {
// 				port: 1338,
// 				hostname: '0.0.0.0'
// 			},
// 			livereload: {
// 				options: {
// 					middleware: function ( connect ) {
// 						return [
// 							connect.compress(),
// 							lrSnippet,
// 							mountFolder( connect, grunt.config.process( '<%= config.tmp %>' ) )
// 						]
// 					}
// 				}
// 			}
// 		},

// 		watch: {
// 			options: {
// 				interrupt: true,
// 				atBegin: true,
// 				livereload: true
// 			},
// 			less: {
// 				files: [ '<%= config.source %>/styles/**/*.less' ],
// 				tasks: [ 'less:site' ]
// 			},
// 			jekyll: {
// 				files: [
// 					'<%= config.source %>/_*/**/*.{markdown,md,html}',
// 					'<%= config.source %>/_config.yml',
// 					'<%= config.source %>/*.{markdown,md,html}'
// 				],
// 				tasks: [ 'shell:build', 'less:site' ]
// 			}
// 		}

// 	})




// 	grunt.registerTask( 'server', [
// 		'shell:build',
// 		'less:site',
// 		'connect:livereload',
// 		'open',
// 		'watch',
// 	])

// 	grunt.registerTask( 'default', [ 'server' ] )
// }



// }())
