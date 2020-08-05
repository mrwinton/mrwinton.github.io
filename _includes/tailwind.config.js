module.exports = {
  purge: {
    enabled: true,
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
