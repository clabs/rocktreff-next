module.exports = {
  plugins: [
    require('autoprefixer'),
    require('@fullhuman/postcss-purgecss')({
      content: ['./layouts/**/*.html', './content/**/*.md'],
      safelist: { standard: [/^skrollr/, /^sr-/] }
    })
  ]
}
