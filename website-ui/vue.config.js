process.env.VUE_APP_VERSION = require('./package.json').version

// Determine the API URL based on environment
const apiUrl = process.env.NODE_ENV === 'production'
    ? 'http://l4d2stats-api:8081'
    : 'http://localhost:8081';

console.log(`Using API URL: ${apiUrl}`);

module.exports = {
    devServer: {
        proxy: {
            '^/api': {
                target: apiUrl,
                changeOrigin: true
            }
        }
    },
}
