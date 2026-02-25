local M = {}

local EXTENSIONS = { "", ".vue", ".js", ".ts", ".jsx", ".tsx" }

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function find_with_extension(base_path)
  for _, ext in ipairs(EXTENSIONS) do
    local path = base_path .. ext
    if file_exists(path) then
      return path
    end
  end
  return nil
end

function M.find_project_root(start_dir)
  local config = require("vue-goto-component.config")
  local dir = start_dir

  while dir ~= "/" do
    for _, marker in ipairs(config.options.root_markers) do
      if file_exists(dir .. "/" .. marker) or vim.fn.isdirectory(dir .. "/" .. marker) == 1 then
        return dir
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil
end

function M.resolve_alias_path(path, project_root)
  if not path:match("^[@~]/") or not project_root then
    return nil
  end
  return find_with_extension(project_root .. "/" .. path:gsub("^[@~]/", ""))
end

function M.resolve_relative_path(path, current_dir)
  if not path:match("^%.") then
    return nil
  end
  return find_with_extension(vim.fn.simplify(current_dir .. "/" .. path))
end

function M.resolve_node_module(path, project_root)
  if path:match("^[/@~%.]") or not project_root then
    return nil
  end

  local node_path = project_root .. "/node_modules/" .. path
  local entries = { "/dist/index.js", "/index.js", "/dist/index.esm.js", ".js" }

  for _, entry in ipairs(entries) do
    if file_exists(node_path .. entry) then
      return node_path .. entry
    end
  end

  local pkg = node_path .. "/package.json"
  if file_exists(pkg) then
    local content = table.concat(vim.fn.readfile(pkg), "\n")
    local main = content:match('"main"%s*:%s*"([^"]+)"')
    if main and file_exists(node_path .. "/" .. main) then
      return node_path .. "/" .. main
    end
  end

  return nil
end

function M.resolve(import_path, current_file)
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  local project_root = M.find_project_root(current_dir)

  return M.resolve_alias_path(import_path, project_root)
    or M.resolve_relative_path(import_path, current_dir)
    or M.resolve_node_module(import_path, project_root)
end

return M
