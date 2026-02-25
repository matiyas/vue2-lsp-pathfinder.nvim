if vim.g.loaded_vue_goto_component then
  return
end
vim.g.loaded_vue_goto_component = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    vim.keymap.set("n", "gd", function()
      require("vue-goto-component").goto_definition()
    end, { buffer = true, desc = "Go to definition (Vue)" })
  end,
})
