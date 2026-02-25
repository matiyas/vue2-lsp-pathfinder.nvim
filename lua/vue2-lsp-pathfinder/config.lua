local M = {}

local defaults = {
  fallback = function()
    vim.lsp.buf.definition()
  end,
  filetypes = { "vue" },
  root_markers = { "package.json", "nuxt.config.js", "nuxt.config.ts", ".git" },
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
