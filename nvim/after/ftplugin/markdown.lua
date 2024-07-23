-- Enable hard line wrapping for markdown files.
local options = {
  wrap = false, -- soft line wrapping (only affects how text is displayed)
  textwidth = 80, -- text longer than this width will be broken after whitespace
  -- linebreak = true, -- break lines at natural points (e.g. words, boundaries)
  -- breakindent = true -- maintain indentation for wrapped lines
}

vim.opt.formatoptions = vim.opt.formatoptions
  + "t" -- auto-wrap text using textwidth
  + "c" -- auto-wrap comments using textwidth
  + "]" -- respect textwidth rigorously

for key, val in pairs(options) do
  vim.opt[key] = val
end
