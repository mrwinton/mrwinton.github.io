module.exports = {
  plugins: [
    require("postcss-import"),
    require("tailwindcss")("./_includes/tailwind.config.js"),
    require("autoprefixer"),
    ...process.env.NODE_ENV === 'production'
      ? [require("cssnano")()]
      : []
  ]
};
