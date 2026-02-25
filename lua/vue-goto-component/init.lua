local config = require("vue-goto-component.config")
local navigation = require("vue-goto-component.navigation")
local parser = require("vue-goto-component.parser")

local M = {}

function M.goto_definition()
  if vim.bo.filetype ~= "vue" then
    config.options.fallback()
    return
  end

  local filepath = vim.api.nvim_buf_get_name(0)

  if navigation.try_import_navigation(filepath) then
    return
  end
  if navigation.try_component_navigation(filepath) then
    return
  end
  if navigation.try_property_navigation(parser.get_word_under_cursor()) then
    return
  end

  config.options.fallback()
end

function M.setup(opts)
  config.setup(opts)
end

return M
