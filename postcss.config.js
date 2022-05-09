module.exports = {
  plugins: [
    require( 'autoprefixer' )({browsers: '> 5%'}),
    require( 'cssnano' )()
  ]
}
