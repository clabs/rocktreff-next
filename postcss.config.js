module.exports = {
  plugins: [
    require( 'pixrem' )(),
    require( 'autoprefixer' )({browsers: '> 5%'}),
    require( 'cssnano' )()
  ]
}
