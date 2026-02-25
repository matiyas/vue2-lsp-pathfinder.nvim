# vue-goto-component.nvim

Enhanced go-to-definition for Vue.js files in Neovim.

## Why This Plugin?

Standard LSP servers like Volar work well for most Vue.js navigation, but they struggle with certain patterns that are common in Vue 2 and legacy codebases:

- **Vue 2 Options API**: LSP can't reliably navigate to definitions in `methods`, `computed`, `data`, `props`, and `watch` sections when referenced via `this.propertyName`
- **Mixins**: Definitions inside mixin files are invisible to LSP since mixins are merged at runtime
- **Template Components**: Jumping from `<my-component>` in templates to the component file requires kebab-case to PascalCase conversion that LSP doesn't always handle
- **Import Statements**: Quick navigation from import lines to the actual file, with proper alias resolution

This plugin handles these cases **before** falling back to the native LSP, giving you the best of both worlds.

## Features

- Navigate from template tags (`<MyComponent>` or `<my-component>`) to component source files
- Jump to Options API definitions (`methods`, `computed`, `data`, `props`, `watch`)
- Navigate into mixin files to find method and property definitions
- Resolve path aliases (`@/`, `~/`) commonly used in Vue projects
- Resolve relative paths and node_modules imports
- Falls back to native LSP (`vim.lsp.buf.definition()`) when custom navigation doesn't find a match

## Requirements

- Neovim >= 0.9.0
- For LSP fallback functionality (recommended):
  - `vue-language-server` (vue_ls/Volar) - Vue language server
  - `vtsls` or `ts_ls` - TypeScript language server (required by vue_ls)

## Installation

### lazy.nvim (Recommended)

Basic installation:

```lua
{
  "matiyas/vue-goto-component.nvim",
  ft = "vue",
  opts = {},
}
```

### LazyVim Users

If you're using LazyVim, the default `gd` keymap may override this plugin's keymap. Use this configuration to ensure the plugin's `gd` takes priority in Vue files:

```lua
{
  "matiyas/vue-goto-component.nvim",
  ft = { "vue" },
  opts = {},
  config = function()
    require("vue-goto-component").setup()

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        if vim.bo[args.buf].filetype == "vue" then
          -- Defer to run after LazyVim sets up its keymaps
          vim.defer_fn(function()
            vim.keymap.set("n", "gd", function()
              require("vue-goto-component").goto_definition()
            end, { buffer = args.buf, desc = "Go to definition (Vue)" })
          end, 100)
        end
      end,
    })
  end,
}
```

### packer.nvim

```lua
use {
  "matiyas/vue-goto-component.nvim",
  ft = "vue",
  config = function()
    require("vue-goto-component").setup()
  end,
}
```

### vim-plug

```vim
Plug 'matiyas/vue-goto-component.nvim'
```

Then in your config:

```lua
require("vue-goto-component").setup()
```

## LSP Setup

This plugin falls back to `vim.lsp.buf.definition()` when it can't resolve a definition. For the best experience, you should have a working Vue LSP setup.

### Required LSP Servers

Install via Mason (`:MasonInstall`):

```
:MasonInstall vue-language-server vtsls
```

Or add to your Mason configuration:

```lua
{
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      "vue-language-server",
      "vtsls",
    },
  },
}
```

### LSP Configuration

The Vue language server (`vue_ls`) requires a TypeScript language server (`vtsls` or `ts_ls`) to work properly. Here's a working configuration for LazyVim:

```lua
-- lua/plugins/vue-lsp.lua
local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
          settings = {
            vtsls = {
              tsserver = {
                globalPlugins = {
                  {
                    name = "@vue/typescript-plugin",
                    location = mason_packages .. "/vue-language-server/node_modules/@vue/language-server",
                    languages = { "vue" },
                    configNamespace = "typescript",
                    enableForWorkspaceTypeScriptVersions = true,
                  },
                },
              },
            },
          },
        },
        vue_ls = {
          filetypes = { "vue" },
          init_options = {
            typescript = {
              tsdk = mason_packages .. "/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib",
            },
          },
        },
      },
    },
  },
}
```

### Verifying LSP Setup

Open a Vue file and run `:LspInfo`. You should see both `vue_ls` and `vtsls` attached to the buffer.

## Configuration

Default configuration (all options are optional):

```lua
require("vue-goto-component").setup({
  -- Function to call when plugin can't resolve the definition
  fallback = vim.lsp.buf.definition,

  -- Filetypes to enable the plugin for
  filetypes = { "vue" },

  -- Markers used to find the project root directory
  root_markers = { "package.json", "nuxt.config.js", "nuxt.config.ts", ".git" },
})
```

## Usage

The plugin automatically maps `gd` (go to definition) in Vue files. When you press `gd`, the plugin will:

1. Check if cursor is on an import statement → navigate to the imported file
2. Check if cursor is on a component tag in template → navigate to the component file
3. Check if cursor is on a property/method reference → navigate to its definition in Options API sections or mixins
4. If none of the above match → fall back to LSP definition

You can also call the function directly:

```lua
require("vue-goto-component").goto_definition()
```

### Custom Keymap

If you want to use a different keymap or disable the automatic mapping:

```lua
{
  "matiyas/vue-goto-component.nvim",
  ft = "vue",
  keys = {
    { "<leader>gd", function() require("vue-goto-component").goto_definition() end, desc = "Vue go to definition" },
  },
  opts = {},
}
```

## How It Works

### Import Navigation

When the cursor is on an import line:

```javascript
import MyComponent from '@/components/MyComponent.vue'
//                      ^--- cursor here, press gd
```

The plugin resolves the path alias and opens the file.

### Component Navigation

When the cursor is on a component tag in the template:

```html
<template>
  <MyComponent />
  <!-- ^--- cursor here, press gd -->
</template>
```

The plugin finds the import statement for `MyComponent` and navigates to the source file.

### Options API Navigation

When the cursor is on a property or method reference:

```javascript
export default {
  methods: {
    handleClick() {
      this.computedValue  // cursor on computedValue, gd jumps to computed section
      this.fetchData()    // cursor on fetchData, gd jumps to methods section
    }
  },
  computed: {
    computedValue() { /* ... */ }
  }
}
```

### Mixin Navigation

The plugin also searches through mixins:

```javascript
import myMixin from './mixins/myMixin'

export default {
  mixins: [myMixin],
  methods: {
    someMethod() {
      this.mixinMethod()  // cursor here, gd opens myMixin.js at mixinMethod
    }
  }
}
```

## Troubleshooting

### "method textDocument/definition is not supported by any of the servers"

This error means no LSP server with definition support is attached. Make sure you have `vue-language-server` and `vtsls` installed and configured. See [LSP Setup](#lsp-setup).

### "Could not find ts_ls, vtsls, or typescript-tools lsp client required by vue_ls"

The Vue language server requires a TypeScript language server. Install `vtsls`:

```
:MasonInstall vtsls
```

And ensure it's configured to attach to Vue files (see [LSP Configuration](#lsp-configuration)).

### gd not working / using wrong keymap

If you're using LazyVim or another distribution, their default `gd` keymap may override this plugin. Use the [LazyVim Users](#lazyvim-users) configuration to set up the keymap with proper priority.

### Plugin not loading

Ensure the plugin is loaded for Vue files:

```lua
:lua print(vim.inspect(require("lazy").plugins()["vue-goto-component.nvim"]))
```

## Tested Configuration

This plugin has been primarily tested with:

- **Neovim**: 0.10.x / 0.11.x
- **Plugin Manager**: lazy.nvim with LazyVim
- **LSP Servers**: vue-language-server (vue_ls) + vtsls
- **Vue Version**: Vue 2 with Options API, Nuxt 2

While the plugin should work with other configurations (Vetur, ts_ls, Vue 3 Composition API), these have not been extensively tested. Contributions and bug reports for other setups are welcome!

## License

MIT
