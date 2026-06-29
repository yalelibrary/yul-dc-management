// Replicates the Webpacker ProvidePlugin that exposed jQuery globally.
// esbuild's `inject` rewrites bare `$` / `jQuery` references to import these.
import jQuery from "jquery"

export { jQuery as $, jQuery }
