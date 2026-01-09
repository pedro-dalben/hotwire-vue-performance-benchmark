module.exports = {
  extends: 'lighthouse:default',
  settings: {
    onlyCategories: ['performance'],
    skipAudits: ['uses-http2'],
  },
};
