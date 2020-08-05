module.exports = {
  purge: {
    content: [
      './_site/**/*.html'
    ]
  },
  theme: {
    extend: {
      spacing: {
        '2px': '2px',
      },
    },
  },
  variants: {
    rotate: ['responsive', 'hover', 'focus', 'group-hover'],
  },
  plugins: [],
};
