local function augroup(name)
  return vim.api.nvim_create_augroup("iris_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].iris_last_loc then
      return
    end
    vim.b[buf].iris_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

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
-- vim.cmd([[
-- if &diff
--     highlight! link DiffText MatchParen
-- endif
-- ]])

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

-- Enable gitconfig syntax highlighting for files ending in "config"
vim.cmd("autocmd BufNewFile,BufRead *config set filetype=gitconfig")
