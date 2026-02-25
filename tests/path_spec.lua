-- Load the module directly for testing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("path", function()
  local path
  local original_filereadable
  local original_isdirectory
  local mock_files = {}

  setup(function()
    -- Mock vim global
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.tbl_deep_extend = function(mode, ...)
      local result = {}
      for _, tbl in ipairs({ ... }) do
        for k, v in pairs(tbl) do
          result[k] = v
        end
      end
      return result
    end
    _G.vim.deepcopy = function(t)
      if type(t) ~= "table" then
        return t
      end
      local copy = {}
      for k, v in pairs(t) do
        copy[k] = _G.vim.deepcopy(v)
      end
      return copy
    end

    -- Store original functions
    original_filereadable = _G.vim.fn.filereadable
    original_isdirectory = _G.vim.fn.isdirectory

    -- Mock filereadable
    _G.vim.fn.filereadable = function(filepath)
      return mock_files[filepath] and 1 or 0
    end

    -- Mock isdirectory
    _G.vim.fn.isdirectory = function(dirpath)
      return mock_files[dirpath .. "/"] and 1 or 0
    end

    -- Mock fnamemodify
    _G.vim.fn.fnamemodify = function(filepath, modifier)
      if modifier == ":h" then
        return filepath:match("(.+)/[^/]+$") or "/"
      end
      return filepath
    end

    -- Mock simplify
    _G.vim.fn.simplify = function(filepath)
      -- Remove ./ segments
      filepath = filepath:gsub("/%./", "/")
      -- Remove ../ segments with parent
      filepath = filepath:gsub("/[^/]+/%.%.", "")
      return filepath
    end

    -- Mock readfile
    _G.vim.fn.readfile = function()
      return {}
    end

    -- Need to load config first since path depends on it
    require("vue-goto-component.config")
    path = require("vue-goto-component.path")
  end)

  teardown(function()
    _G.vim.fn.filereadable = original_filereadable
    _G.vim.fn.isdirectory = original_isdirectory
  end)

  before_each(function()
    mock_files = {}
  end)

  describe("resolve_alias_path", function()
    it("resolves @ alias path", function()
      mock_files["/project/components/Foo.vue"] = true
      local result = path.resolve_alias_path("@/components/Foo", "/project")
      assert.equals("/project/components/Foo.vue", result)
    end)

    it("resolves ~ alias path", function()
      mock_files["/project/components/Foo.vue"] = true
      local result = path.resolve_alias_path("~/components/Foo", "/project")
      assert.equals("/project/components/Foo.vue", result)
    end)

    it("returns nil for non-alias paths", function()
      local result = path.resolve_alias_path("./components/Foo", "/project")
      assert.is_nil(result)
    end)

    it("returns nil when file not found", function()
      local result = path.resolve_alias_path("@/components/NotFound", "/project")
      assert.is_nil(result)
    end)
  end)

  describe("resolve_relative_path", function()
    it("resolves ./ relative path", function()
      mock_files["/project/src/components/Foo.vue"] = true
      local result = path.resolve_relative_path("./components/Foo", "/project/src")
      assert.equals("/project/src/components/Foo.vue", result)
    end)

    it("resolves ../ relative path", function()
      mock_files["/project/components/Foo.vue"] = true
      local result = path.resolve_relative_path("../components/Foo", "/project/src")
      assert.equals("/project/components/Foo.vue", result)
    end)

    it("returns nil for non-relative paths", function()
      local result = path.resolve_relative_path("@/components/Foo", "/project/src")
      assert.is_nil(result)
    end)
  end)

  describe("resolve_node_module", function()
    it("resolves node_modules with index.js", function()
      mock_files["/project/node_modules/lodash/index.js"] = true
      local result = path.resolve_node_module("lodash", "/project")
      assert.equals("/project/node_modules/lodash/index.js", result)
    end)

    it("resolves node_modules with dist/index.js", function()
      mock_files["/project/node_modules/axios/dist/index.js"] = true
      local result = path.resolve_node_module("axios", "/project")
      assert.equals("/project/node_modules/axios/dist/index.js", result)
    end)

    it("returns nil for alias paths", function()
      local result = path.resolve_node_module("@/components/Foo", "/project")
      assert.is_nil(result)
    end)

    it("returns nil for relative paths", function()
      local result = path.resolve_node_module("./Foo", "/project")
      assert.is_nil(result)
    end)
  end)

  describe("find_project_root", function()
    it("finds root with package.json", function()
      mock_files["/project/package.json"] = true
      local result = path.find_project_root("/project/src/components")
      assert.equals("/project", result)
    end)

    it("finds root with nuxt.config.js", function()
      mock_files["/project/nuxt.config.js"] = true
      local result = path.find_project_root("/project/src/components")
      assert.equals("/project", result)
    end)

    it("returns nil when no root markers found", function()
      local result = path.find_project_root("/some/random/path")
      assert.is_nil(result)
    end)
  end)
end)
