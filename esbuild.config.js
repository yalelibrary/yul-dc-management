// esbuild build script for the application JS bundle.
// Replaces Webpacker; output is written to app/assets/builds where Sprockets
// fingerprints and serves it via javascript_include_tag.
//
//   node esbuild.config.js            # one-off build (used by assets:precompile)
//   node esbuild.config.js --watch    # rebuild on change (used in dev/test)
const esbuild = require("esbuild")
const path = require("path")

const watch = process.argv.includes("--watch")

// Stub Node core modules that browser-targeted deps reference conditionally.
// Mirrors the Webpacker `resolve.fallback: { fs: false, ... }` config.
const stubNodeBuiltins = {
  name: "stub-node-builtins",
  setup(build) {
    const builtins = /^(dgram|fs|net|tls|child_process)$/
    build.onResolve({ filter: builtins }, (args) => ({
      path: args.path,
      namespace: "node-stub",
    }))
    build.onLoad({ filter: /.*/, namespace: "node-stub" }, () => ({
      contents: "module.exports = {}",
    }))
  },
}

const config = {
  entryPoints: [path.join(__dirname, "app/javascript/application.js")],
  bundle: true,
  sourcemap: true,
  outdir: path.join(__dirname, "app/assets/builds"),
  publicPath: "/assets",
  target: ["es2019"],
  loader: { ".woff": "file", ".woff2": "file", ".ttf": "file", ".eot": "file", ".svg": "file" },
  inject: [path.join(__dirname, "app/javascript/jquery.shim.js")],
  plugins: [stubNodeBuiltins],
  logLevel: "info",
}

async function run() {
  if (watch) {
    const ctx = await esbuild.context(config)
    await ctx.watch()
    console.log("[esbuild] watching for changes…")
  } else {
    await esbuild.build(config)
  }
}

run().catch((error) => {
  console.error(error)
  process.exit(1)
})
