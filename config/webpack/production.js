process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const environment = require('./environment')

const config = environment.toWebpackConfig()

// remove config.devtool when upgrading to webpack v5
config.devtool = 'none'

module.exports = config