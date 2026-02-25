local parser = require("vue2-lsp-pathfinder.parser")
local path = require("vue2-lsp-pathfinder.path")

local M = {}

local function file_exists(filepath)
  return vim.fn.filereadable(filepath) == 1
end

local function get_buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function navigate_to(line_num, filepath, word)
  if filepath then
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  end
  vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  vim.cmd("normal! ^")

  local current_line = vim.api.nvim_get_current_line()
  local pos = current_line:find(word, 1, true)
  if pos then
    vim.api.nvim_win_set_cursor(0, { line_num, pos - 1 })
  end
end

local function find_in_mixins(lines, name, filepath)
  for _, mixin in ipairs(parser.find_used_mixins(lines)) do
    local resolved = path.resolve(mixin.path, filepath)
    if resolved and file_exists(resolved) then
      local line = parser.find_in_mixin_file(vim.fn.readfile(resolved), name)
      if line then
        return line, resolved
      end
    end
  end
  return nil, nil
end

local function find_property(name, current_line)
  local lines = get_buffer_lines()
  local sections = parser.parse_sections(lines)
  local section_depths = parser.get_section_depths()

  for section, depth in pairs(section_depths) do
    if sections[section] then
      local line = parser.find_in_section(lines, name, sections[section], depth)
      if line and line ~= current_line then
        return line, nil
      end
    end
  end

  return find_in_mixins(lines, name, vim.api.nvim_buf_get_name(0))
end

function M.try_import_navigation(filepath)
  local import_path = parser.get_import_path_on_line()

  if not import_path then
    return false
  end

  local resolved = path.resolve(import_path, filepath)
  if resolved then
    vim.cmd("edit " .. vim.fn.fnameescape(resolved))
    return true
  end

  return false
end

function M.try_component_navigation(filepath)
  if not parser.is_in_template() then
    return false
  end

  local tag = parser.get_tag_under_cursor()

  if not tag then
    return false
  end

  local import_path = parser.find_import_path(get_buffer_lines(), parser.kebab_to_pascal(tag))

  if not import_path then
    return false
  end

  local resolved = path.resolve(import_path, filepath)
  if resolved then
    vim.cmd("edit " .. vim.fn.fnameescape(resolved))
    return true
  end

  return false
end

function M.try_property_navigation(word)
  if not word or parser.is_keyword(word) then
    return false
  end

  local line, file = find_property(word, vim.fn.line("."))
  if line then
    navigate_to(line, file, word)
    return true
  end

  return false
end

return M
