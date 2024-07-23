-- Highlight yanked selection.
vim.cmd([[
augroup highlight_yank
  autocmd!
  au TextYankPost * silent! lua require('vim.highlight').on_yank({higroup = 'Search', timeout = 500})
augroup END
]])

-- Store cursor position & reset the cursor position.
-- Remove trailing whitespaces except in '.md' files.
-- Remove trailing new lines at the end of file
-- Replace trailing newlines with one newline in '.c' or '.h' files
-- Restore cursor position
vim.cmd([[
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre *[^m][^d] %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre *.[ch] %s/\%$/\r/e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])
]])

-- Turns off highlighting on the bits of code that are changed, so the line that is changed is highlighted
-- but the actual text that has changed stands out on the line and is readable.
vim.cmd([[
if &diff
    highlight! link DiffText MatchParen
endif
]])

-- Highlight all columns longer than 108 characters.
-- vim.cmd([[
-- augroup vimrc_autocmds
--   autocmd BufEnter * highlight OverLength ctermbg=darkgrey guibg=#592929
--   autocmd BufEnter * match OverLength /\%108v.*/
-- augroup END
-- ]])

-- Restore blinking beam cursor after exiting neovim.
vim.cmd([[
augroup RestoreCursorShapeOnExit
    autocmd!
    autocmd VimLeave * set guicursor=a:ver20-blinkwait175-blinkoff150-blinkon175
augroup END
]])

-- Enable gitconfig syntax highlighting for file named config
vim.cmd("autocmd BufNewFile,BufRead *config set filetype=gitconfig")
