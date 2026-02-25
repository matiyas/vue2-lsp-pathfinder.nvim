std = "luajit"
globals = { "vim" }
max_line_length = 120
codes = true

exclude_files = {
  "tests/minimal_init.lua",
}

ignore = {
  "212", -- unused argument (common in callbacks)
}
