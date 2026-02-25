if vim.g.loaded_vue2_lsp_pathfinder then
  return
end
vim.g.loaded_vue2_lsp_pathfinder = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    vim.keymap.set("n", "gd", function()
      require("vue2-lsp-pathfinder").goto_definition()
    end, { buffer = true, desc = "Go to definition (Vue)" })
  end,
})
