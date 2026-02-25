-- Minimal init for running tests
vim.opt.rtp:append(".")

-- Mock vim functions that may not be available in test environment
vim.fn.filereadable = vim.fn.filereadable or function()
  return 0
end
vim.fn.isdirectory = vim.fn.isdirectory or function()
  return 0
end
