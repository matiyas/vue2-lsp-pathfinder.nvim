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
- A Vue LSP server (volar/vue_ls) is recommended for fallback functionality

## Installation

### lazy.nvim

```lua
{
  "matiyas/vue-goto-component.nvim",
  ft = "vue",
  opts = {},
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

## License

MIT
