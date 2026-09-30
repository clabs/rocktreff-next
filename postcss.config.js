module.exports = {
  plugins: [
    require('autoprefixer'),
    require('@fullhuman/postcss-purgecss')({
      content: ['./layouts/**/*.html', './content/**/*.md', './assets/js/**/*.js'],
      safelist: { standard: [/^skrollr/, /^sr-/] }
    })
  ]
}
