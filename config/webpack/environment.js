const { environment } = require('@rails/webpacker')
const datatables = require('./loaders/datatables')
const webpack = require("webpack")
environment.loaders.append('datatables', datatables)
environment.plugins.append("Provide", new webpack.ProvidePlugin({

$: 'jquery',

jQuery: 'jquery',

Popper: ['popper.js', 'default']

}))

// will be needed when we upgrade to webpack v5
// const customConfig = {
//   resolve: {
//     fallback: {
//       dgram: false,
//       fs: false,
//       net: false,
//       tls: false,
//       child_process: false
//     }
//   }
// };

// environment.config.delete('node.dgram')
// environment.config.delete('node.fs')
// environment.config.delete('node.net')
// environment.config.delete('node.tls')
// environment.config.delete('node.child_process')

// environment.config.merge(customConfig);

module.exports = environment
