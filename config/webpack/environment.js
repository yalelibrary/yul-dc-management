const { environment } = require('@rails/webpacker')
const datatables = require('./loaders/datatables')
const webpack = require("webpack")
environment.loaders.append('datatables', datatables)
environment.plugins.append("Provide", new webpack.ProvidePlugin({

$: 'jquery',

jQuery: 'jquery',

Popper: ['popper.js', 'default']

}))

module.exports = environment
