module.exports = {
  content: [
    './**/*.html'
  ],
  theme: {
    extend: {
      spacing: {
        '2px': '2px',
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
};
