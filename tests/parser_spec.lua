-- Load the module directly for testing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("parser", function()
  local parser

  setup(function()
    -- Mock vim global
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.api = _G.vim.api or {}

    parser = require("vue2-lsp-pathfinder.parser")
  end)

  describe("kebab_to_pascal", function()
    it("converts simple kebab-case to PascalCase", function()
      assert.equals("MyComponent", parser.kebab_to_pascal("my-component"))
    end)

    it("handles single word", function()
      assert.equals("Component", parser.kebab_to_pascal("component"))
    end)

    it("handles multiple hyphens", function()
      assert.equals("MyAwesomeComponent", parser.kebab_to_pascal("my-awesome-component"))
    end)

    it("handles already PascalCase", function()
      assert.equals("MyComponent", parser.kebab_to_pascal("MyComponent"))
    end)
  end)

  describe("is_keyword", function()
    it("returns true for JavaScript keywords", function()
      assert.is_true(parser.is_keyword("function"))
      assert.is_true(parser.is_keyword("return"))
      assert.is_true(parser.is_keyword("const"))
      assert.is_true(parser.is_keyword("this"))
    end)

    it("returns false for non-keywords", function()
      assert.is_false(parser.is_keyword("myVariable"))
      assert.is_false(parser.is_keyword("handleClick"))
      assert.is_false(parser.is_keyword("computed"))
    end)
  end)

  describe("find_import_path", function()
    it("finds standard import path", function()
      local lines = {
        "import MyComponent from '@/components/MyComponent.vue'",
      }
      assert.equals("@/components/MyComponent.vue", parser.find_import_path(lines, "MyComponent"))
    end)

    it("finds dynamic import path", function()
      local lines = {
        "MyComponent: () => import('@/components/MyComponent.vue')",
      }
      assert.equals("@/components/MyComponent.vue", parser.find_import_path(lines, "MyComponent"))
    end)

    it("returns nil when import not found", function()
      local lines = {
        "import OtherComponent from '@/components/Other.vue'",
      }
      assert.is_nil(parser.find_import_path(lines, "MyComponent"))
    end)
  end)

  describe("get_script_range", function()
    it("finds script section", function()
      local lines = {
        "<template>",
        "  <div></div>",
        "</template>",
        "<script>",
        "export default {}",
        "</script>",
      }
      local start_line, end_line = parser.get_script_range(lines)
      assert.equals(4, start_line)
      assert.equals(6, end_line)
    end)

    it("returns nil when no script section", function()
      local lines = {
        "<template>",
        "  <div></div>",
        "</template>",
      }
      local start_line, end_line = parser.get_script_range(lines)
      assert.is_nil(start_line)
      assert.is_nil(end_line)
    end)
  end)

  describe("parse_sections", function()
    it("finds methods section", function()
      local lines = {
        "<script>",
        "export default {",
        "  methods: {",
        "    handleClick() {}",
        "  }",
        "}",
        "</script>",
      }
      local sections = parser.parse_sections(lines)
      assert.is_not_nil(sections.methods)
      assert.equals(3, sections.methods.start)
    end)

    it("finds computed section", function()
      local lines = {
        "<script>",
        "export default {",
        "  computed: {",
        "    myValue() { return 1 }",
        "  }",
        "}",
        "</script>",
      }
      local sections = parser.parse_sections(lines)
      assert.is_not_nil(sections.computed)
    end)

    it("finds data section", function()
      local lines = {
        "<script>",
        "export default {",
        "  data() {",
        "    return { foo: 1 }",
        "  }",
        "}",
        "</script>",
      }
      local sections = parser.parse_sections(lines)
      assert.is_not_nil(sections.data)
    end)
  end)

  describe("find_in_section", function()
    it("finds method definition", function()
      local lines = {
        "<script>",
        "export default {",
        "  methods: {",
        "    handleClick() {}",
        "  }",
        "}",
        "</script>",
      }
      local sections = parser.parse_sections(lines)
      local line = parser.find_in_section(lines, "handleClick", sections.methods, 1)
      assert.equals(4, line)
    end)

    it("finds async method definition", function()
      local lines = {
        "<script>",
        "export default {",
        "  methods: {",
        "    async fetchData() {}",
        "  }",
        "}",
        "</script>",
      }
      local sections = parser.parse_sections(lines)
      local line = parser.find_in_section(lines, "fetchData", sections.methods, 1)
      assert.equals(4, line)
    end)
  end)

  describe("find_used_mixins", function()
    it("finds mixins used in component", function()
      local lines = {
        "import myMixin from './mixins/myMixin'",
        "import otherMixin from './mixins/other'",
        "<script>",
        "export default {",
        "  mixins: [myMixin, otherMixin],",
        "}",
        "</script>",
      }
      local mixins = parser.find_used_mixins(lines)
      assert.equals(2, #mixins)
      assert.equals("myMixin", mixins[1].name)
      assert.equals("./mixins/myMixin", mixins[1].path)
    end)

    it("returns empty when no mixins", function()
      local lines = {
        "<script>",
        "export default {",
        "  methods: {}",
        "}",
        "</script>",
      }
      local mixins = parser.find_used_mixins(lines)
      assert.equals(0, #mixins)
    end)
  end)
end)
