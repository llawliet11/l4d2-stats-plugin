process.env.VUE_APP_VERSION = require('./package.json').version
module.exports = {
    devServer: {
        proxy: {
            '^/api': {
                target: 'http://l4d2stats-api:8081'
            }
        }
    },
}
