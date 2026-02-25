rockspec_format = "3.0"
package = "vue2-lsp-pathfinder.nvim"
version = "1.0.0-1"

description = {
  summary = "Pathfinder for Vue 2 / Nuxt 2 codebases — navigates where LSP can't reach",
  detailed = [[
    Enhanced go-to-definition for Vue.js files in Neovim.
    Navigates Options API definitions (methods, computed, data, props, watch),
    mixins, template components, and import statements.
    Falls back to native LSP when custom navigation doesn't find a match.
  ]],
  license = "MIT",
  homepage = "https://github.com/matiyas/vue2-lsp-pathfinder.nvim",
  labels = { "neovim", "vue", "nuxt", "lsp", "navigation" },
}

dependencies = {
  "lua >= 5.1",
}

source = {
  url = "git://github.com/matiyas/vue2-lsp-pathfinder.nvim.git",
  tag = "v1.0.0",
}

build = {
  type = "builtin",
  copy_directories = { "lua", "plugin" },
}
