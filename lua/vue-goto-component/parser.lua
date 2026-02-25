local M = {}

local HTML_TAGS = {
  a = 1,
  abbr = 1,
  address = 1,
  area = 1,
  article = 1,
  aside = 1,
  audio = 1,
  b = 1,
  base = 1,
  bdi = 1,
  bdo = 1,
  blockquote = 1,
  body = 1,
  br = 1,
  button = 1,
  canvas = 1,
  caption = 1,
  cite = 1,
  code = 1,
  col = 1,
  colgroup = 1,
  data = 1,
  datalist = 1,
  dd = 1,
  del = 1,
  details = 1,
  dfn = 1,
  dialog = 1,
  div = 1,
  dl = 1,
  dt = 1,
  em = 1,
  embed = 1,
  fieldset = 1,
  figcaption = 1,
  figure = 1,
  footer = 1,
  form = 1,
  h1 = 1,
  h2 = 1,
  h3 = 1,
  h4 = 1,
  h5 = 1,
  h6 = 1,
  head = 1,
  header = 1,
  hr = 1,
  html = 1,
  i = 1,
  iframe = 1,
  img = 1,
  input = 1,
  ins = 1,
  kbd = 1,
  label = 1,
  legend = 1,
  li = 1,
  link = 1,
  main = 1,
  map = 1,
  mark = 1,
  meta = 1,
  meter = 1,
  nav = 1,
  noscript = 1,
  object = 1,
  ol = 1,
  optgroup = 1,
  option = 1,
  output = 1,
  p = 1,
  param = 1,
  picture = 1,
  pre = 1,
  progress = 1,
  q = 1,
  rp = 1,
  rt = 1,
  ruby = 1,
  s = 1,
  samp = 1,
  script = 1,
  section = 1,
  select = 1,
  small = 1,
  source = 1,
  span = 1,
  strong = 1,
  style = 1,
  sub = 1,
  summary = 1,
  sup = 1,
  table = 1,
  tbody = 1,
  td = 1,
  template = 1,
  textarea = 1,
  tfoot = 1,
  th = 1,
  thead = 1,
  time = 1,
  title = 1,
  tr = 1,
  track = 1,
  u = 1,
  ul = 1,
  var = 1,
  video = 1,
  wbr = 1,
}

local KEYWORDS = {
  ["true"] = 1,
  ["false"] = 1,
  ["null"] = 1,
  ["undefined"] = 1,
  ["if"] = 1,
  ["else"] = 1,
  ["for"] = 1,
  ["while"] = 1,
  ["do"] = 1,
  ["return"] = 1,
  ["function"] = 1,
  ["const"] = 1,
  ["let"] = 1,
  ["var"] = 1,
  ["this"] = 1,
  ["new"] = 1,
  ["typeof"] = 1,
  ["instanceof"] = 1,
  ["import"] = 1,
  ["export"] = 1,
  ["default"] = 1,
  ["from"] = 1,
  ["async"] = 1,
  ["await"] = 1,
  ["class"] = 1,
  ["extends"] = 1,
  ["in"] = 1,
  ["of"] = 1,
  ["switch"] = 1,
  ["case"] = 1,
  ["break"] = 1,
  ["try"] = 1,
  ["catch"] = 1,
  ["finally"] = 1,
  ["throw"] = 1,
}

local SECTION_DEPTHS = { computed = 1, methods = 1, data = 2, props = 1, watch = 1 }

local function count_braces(line)
  local open = select(2, line:gsub("{", "")) + select(2, line:gsub("%[", ""))
  local close = select(2, line:gsub("}", "")) + select(2, line:gsub("%]", ""))
  return open - close
end

local function escape_pattern(str)
  return str:gsub("([%.%-%+%[%]%(%)%$%^%%%?%*])", "%%%1")
end

function M.kebab_to_pascal(str)
  return str:gsub("^%l", string.upper):gsub("%-(%l)", function(c)
    return c:upper()
  end)
end

function M.is_keyword(word)
  return KEYWORDS[word] ~= nil
end

function M.get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local start_col, end_col = col, col

  while start_col > 1 and line:sub(start_col - 1, start_col - 1):match("[%w_]") do
    start_col = start_col - 1
  end
  while end_col <= #line and line:sub(end_col, end_col):match("[%w_]") do
    end_col = end_col + 1
  end

  if start_col >= end_col then
    return nil
  end
  return line:sub(start_col, end_col - 1)
end

local function find_last_unclosed_bracket(text)
  local last_open = 0
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "<" then
      last_open = i
    elseif c == ">" then
      last_open = 0
    end
  end
  return last_open
end

function M.get_tag_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local last_open = find_last_unclosed_bracket(line:sub(1, col))

  if last_open == 0 then
    return nil
  end

  local after_open = line:sub(last_open + 1)
  local tag = after_open:match("^/?([%w%-]+)")

  if not tag or HTML_TAGS[tag:lower()] then
    return nil
  end

  local tag_start = last_open + (after_open:sub(1, 1) == "/" and 2 or 1)
  local tag_end = tag_start + #tag - 1

  if col < tag_start or col > tag_end then
    return nil
  end

  return tag
end

function M.is_in_template()
  local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line("."), false)
  local in_template = false

  for _, line in ipairs(lines) do
    if line:match("^<template") then
      in_template = true
    elseif line:match("^</template>") then
      in_template = false
    end
  end

  return in_template
end

function M.get_script_range(lines)
  local start_line, end_line = nil, nil

  for i, line in ipairs(lines) do
    if line:match("^%s*<script") then
      start_line = i
    elseif line:match("^%s*</script>") and start_line then
      end_line = i
      break
    end
  end

  return start_line, end_line
end

function M.find_import_path(lines, name)
  for _, line in ipairs(lines) do
    local n, p = line:match("import%s+(" .. name .. ")%s+from%s+[\"']([^\"']+)[\"']")
    if n then
      return p
    end

    n, p = line:match("(" .. name .. ")%s*:%s*%(%s*%)%s*=>%s*import%s*%([\"']([^\"']+)[\"']%)")
    if n then
      return p
    end
  end

  return nil
end

function M.get_import_path_on_line()
  local line = vim.api.nvim_get_current_line()

  return line:match("import%s+[%w_]+%s+from%s+[\"']([^\"']+)[\"']") or line:match("import%s*%([\"']([^\"']+)[\"']%)")
end

local function is_section_start(line, section)
  return line:match("^%s*" .. section .. "%s*%(%s*%)%s*{")
    or line:match("^%s*" .. section .. "%s*:%s*{")
    or line:match("^%s*" .. section .. "%s*:%s*%[")
    or line:match("^%s*" .. section .. "%s*:%s*function")
    or line:match("^%s*async%s+" .. section .. "%s*%(")
end

local function find_section_end(lines, start_idx, end_idx)
  local depth = 0

  for j = start_idx, end_idx do
    depth = depth + count_braces(lines[j])
    if depth == 0 and j > start_idx then
      return j
    end
  end

  return end_idx
end

function M.parse_sections(lines)
  local script_start, script_end = M.get_script_range(lines)

  if not script_start then
    return {}
  end

  local sections = {}
  local in_export, export_depth = false, 0

  for i = script_start, script_end do
    local line = lines[i]
    if line:match("export%s+default") then
      in_export = true
    end
    if in_export then
      export_depth = export_depth + count_braces(line)
      for section, _ in pairs(SECTION_DEPTHS) do
        if is_section_start(line, section) then
          sections[section] = { start = i, finish = find_section_end(lines, i, script_end) }
        end
      end
      if export_depth == 0 then
        break
      end
    end
  end

  return sections
end

local function matches_definition(line, escaped_name)
  if line:match("^%s*" .. escaped_name .. "%s*%(") then
    return true
  end
  if line:match("^%s*async%s+" .. escaped_name .. "%s*%(") then
    return true
  end
  if line:match("^%s*%.%.%.") then
    return false
  end

  if line:match("^%s*" .. escaped_name .. "%s*:") then
    local after = line:match("^%s*" .. escaped_name .. "%s*:%s*(.+)")
    return not after or not after:match("^this%.")
  end

  if line:match("^%s*" .. escaped_name .. "%s*,$") then
    return true
  end
  if line:match("^%s*" .. escaped_name .. "%s*$") then
    return true
  end

  return false
end

function M.find_in_section(lines, name, section, target_depth)
  if not section then
    return nil
  end

  local escaped = escape_pattern(name)
  local depth = 0

  for i = section.start, section.finish do
    if i == section.start then
      depth = count_braces(lines[i])
    else
      if depth == target_depth and matches_definition(lines[i], escaped) then
        return i
      end
      depth = depth + count_braces(lines[i])
    end
  end

  return nil
end

function M.find_used_mixins(lines)
  local imports = {}

  for _, line in ipairs(lines) do
    local name, path = line:match("import%s+([%w_]+)%s+from%s+[\"']([^\"']+)[\"']")
    if name then
      imports[name] = path
    end
  end

  local script_start, script_end = M.get_script_range(lines)

  if not script_start then
    return {}
  end

  local used, in_mixins, depth = {}, false, 0

  for i = script_start, script_end do
    local line = lines[i]
    if line:match("^%s*mixins%s*:%s*%[") then
      in_mixins = true
    end
    if in_mixins then
      depth = depth + select(2, line:gsub("%[", "")) - select(2, line:gsub("%]", ""))
      for mixin_name in line:gmatch("([%w_]+)") do
        if imports[mixin_name] then
          table.insert(used, { name = mixin_name, path = imports[mixin_name] })
        end
      end
      if depth == 0 then
        break
      end
    end
  end

  return used
end

function M.find_in_mixin_file(mixin_lines, name)
  local escaped = escape_pattern(name)

  for i, line in ipairs(mixin_lines) do
    if
      line:match("^%s*" .. escaped .. "%s*%(")
      or line:match("^%s*async%s+" .. escaped .. "%s*%(")
      or line:match("^%s*" .. escaped .. "%s*:")
    then
      return i
    end
  end

  return nil
end

function M.get_section_depths()
  return SECTION_DEPTHS
end

return M
