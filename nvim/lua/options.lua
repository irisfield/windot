local options = {
  autoindent = true, -- copy indent from current line when starting a new line
  autowrite = true, -- automatically write file on certain commands when modified
  autowriteall = true, -- extends the functionality of autowrite
  backup = false, -- disable creating a backup before overwriting a file
  clipboard = "unnamedplus", -- always use the system clipboard for all operations
  cmdheight = 1, -- number lines to use for the command-line
  completeopt = { -- options for insert mode completion (:h "completeopt")
    "menuone", -- show popup-menu even with one match
    "noselect", -- do not automatically select the first match
  },
  conceallevel = 0, -- show concealed characters in markdown files (e.g. ``)
  cursorline = true, -- highlight the current line (useful to spot the cursor)
  expandtab = true, -- use spaces instead of tabs in insert mode
  fileencoding = "utf-8", -- set file content encoding for the current buffer
  -- fileformats = "unix", -- force unix line endings
  hlsearch = false, -- do not highlight previous search pattern matches
  ignorecase = true, -- ignore letter case in search patterns (overruled by "\C")
  inccommand = "split", -- show the effects of commands incrementally
  incsearch = true, -- highlight where the pattern matches while typing
  hidden = false, -- do not close buffers when they become hidden
  list = true, -- enable list mode to display invisible characters
  listchars = { -- characters to use in list mode
    tab = "‣ˑ", -- tab character
    trail = "·", -- trailing whitespace
  },
  mouse = "a", -- enable mouse support for "a"ll modes
  number = true, -- print the line number in front of each line
  numberwidth = 4, -- width of the line number column
  pumheight = 10, -- maximum number of items in popup-menu
  pumblend = 30, -- pseudo-transparency for popup-menu
  relativenumber = true, -- show relative line numbers
  scrolloff = 8, -- minimum lines to keep above and below the cursor
  shell = "zsh", -- shell to use for "!" and ":!" commands
  shiftwidth = 2, -- number of spaces for each step of auto-indent, >>, and <<
  showmatch = true, -- briefly jump to matching bracket, brace, or parenthesis
  showmode = false, -- do not show mode message on the last line (INSERT, NORMAL, etc)
  showtabline = 1, -- show tab page labels if more than one tab is open
  sidescroll = 8, -- minimum columns to scroll horizontally
  sidescrolloff = 8, -- minimum screen columns to keep to the left and right of the cursor
  signcolumn = "yes", -- always display sign column (useful for LSP)
  smartcase = true, -- override "ignorecase" if search pattern contains uppercase
  smartindent = true, -- syntax-aware auto-indent when starting a new line
  splitbelow = true, -- open new split below current window (:split)
  splitright = true, -- open new split right of current window (:vsplit)
  swapfile = false, -- disable using a swapfile for the buffer
  tabstop = 2, -- number of spaces for tab character (also change shiftwidth)
  termguicolors = true, -- enable 24-bit true color in the TUI
  textwidth = 0, -- disable hard line wrapping (when set, use "gqq" to format line)
  timeoutlen = 1500, -- time to wait in milliseconds for mapped sequence to complete
  undofile = true, -- automatically save undo history to a file
  updatetime = 300, -- time of no cursor movement in milliseconds to trigger CursorHold
  wildoptions = "pum", -- display completion matches using the popup-menu
  wrap = false, -- disable soft line wrapping (this is a visual effect)
}

for key, val in pairs(options) do
  vim.opt[key] = val
end

-- list-like options
-- (https://neovim.io/doc/user/options.html#'shortmess')
vim.opt.shortmess = vim.opt.shortmess
  -- default "filnxtToOF"
  - "i" -- use '[noel]' instead of '[Incomplete last line]'
  + "I" -- do not show the intro message when starting neovim
  + "c" -- do not pass ins-completion-menu status messages

vim.opt.iskeyword = vim.opt.iskeyword
  + "-" -- treat dash-separated words as one word (text object)
  - "_" -- treat underscore_seperated words as seperate words (text object)

-- fo-table gets overwritten by ftplugins (:verb set fo)
-- (https://neovim.io/doc/user/change.html#fo-table)
vim.opt.formatoptions = vim.opt.formatoptions
  -- default "tcqj"
  + "t" -- auto-wrap text using textwidth
  + "c" -- auto-wrap comments using textwidth, inserting the current comment leader automatically
  + "r" -- automatically insert the current comment leader after hitting <Enter> in insert mode
  + "q" -- allow formatting comments with <gq>
  + "n" -- recognize numbered lists for text wrapping (:h fo-n)
  + "M" -- when joining lines, don't insert a space before or after a multibyte character
  + "1" -- do not break a line after a one-letter word, break it before instead (if possible)
  + "j" -- where it makes sense, remove a comment leader when joining lines
  + "l" -- when entering insert mode, break lines longer than 'textwidth'
  - "]" -- respect textwidth rigorously (with this flag set, no line can be longer than textwidth)

local disabled_built_ins = {
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "tutor_mode_plugin",
  "fzf",
  "matchit",
  "shada_plugin",
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end
