module.exports = {
    test: /datatables\.net.*.js/,
    loader: 'imports-loader',
    options: {
        additionalCode: 'var define = false;'
    }
}
