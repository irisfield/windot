-- (https://neovim.io/doc/user/intro.html#tab)
local keymaps = {
  insert_mode = {
    -- write buffer to file
    ["<C-z>"] = "<ESC>:w<CR>",
    -- switch between split windows
    ["<C-h>"] = "<C-w>h",
    ["<C-j>"] = "<C-w>j",
    ["<C-k>"] = "<C-w>k",
    ["<C-l>"] = "<C-w>l",
  },
  normal_mode = {
    -- write buffer to file
    ["<C-z>"] = ":w<CR>",
    -- open file explorer
    ["<leader>e"] = ":NvimTreeToggle<CR>",
    -- close buffer
    ["<A-d>"] = ":bdelete<CR>",
    -- switch between tabs
    ["<A-h>"] = ":tabprevious<CR>",
    ["<A-l>"] = ":tabnext<CR>",
    -- switch between buffers
    ["<A-j>"] = ":bprevious<CR>",
    ["<A-k>"] = ":bnext<CR>",
    -- switch between split windows
    ["<C-h>"] = "<C-w>h",
    ["<C-j>"] = "<C-w>j",
    ["<C-k>"] = "<C-w>k",
    ["<C-l>"] = "<C-w>l",
    -- resize split window
    ["<C-Up>"] = ":resize -2<CR>",
    ["<C-Down>"] = ":resize +2<CR>",
    ["<C-Left>"] = ":vertical resize +2<CR>",
    ["<C-Right>"] = ":vertical resize -2<CR>",
    -- telescope
    ["<leader>f"] = ":Telescope find_files<CR>",
    ["<leader>F"] = ":Telescope live_grep<CR>",
  },
  visual_mode = {
    -- write buffer to file
    ["<C-z>"] = "<ESC>:w<CR>",
    -- paste without yanking the replaced selection
    ["p"] = '"_dP',
    -- persistent indent mode
    ["<"] = "<gv",
    [">"] = ">gv",
    -- move the selected line(s) or block of characters up or down
    ["<A-j>"] = ':move ">+1<CR>gv-gv',
    ["<A-k>"] = ':move "<-2<CR>gv-gv',
  },
  visual_block_mode = {
    -- write buffer to file
    ["<C-z>"] = "<ESC>:w<CR>",
    -- move the selected line(s) or block of characters up or down
    ["<A-j>"] = ':move ">+1<CR>gv-gv',
    ["<A-k>"] = ':move "<-2<CR>gv-gv',
  },
  command_mode = {},
  term_mode = {
    -- terminal navigation inside neovim
    ["<C-h>"] = "<C-\\><C-N><C-w>h",
    ["<C-j>"] = "<C-\\><C-N><C-w>j",
    ["<C-k>"] = "<C-\\><C-N><C-w>k",
    ["<C-l>"] = "<C-\\><C-N><C-w>l",
  },
}

local opts = { noremap = true, silent = true }

local mode_opts = {
  insert_mode = opts,
  normal_mode = opts,
  visual_mode = opts,
  visual_block_mode = opts,
  command_mode = opts,
  term_mode = { silent = true },
}

local mode_adapters = {
  insert_mode = "i",
  normal_mode = "n",
  visual_mode = "v",
  visual_block_mode = "x",
  command_mode = "c",
  term_mode = "t",
}

-- Helper to set individual keymaps.
-- @param mode The value corresponding to one of the keys in mode_adapters.
-- @param key The keyboard key to bind.
-- @param val A mapping or a tuple of mapping and user defined opt.
-- @param opt The options to pass
local function set_keymaps(mode, key, val, opt)
  if type(val) == "table" then
    opt = val[1]
    val = opt[2]
  end
  if val then
    vim.api.nvim_set_keymap(mode, key, val, opt)
  else
    pcall(vim.api.nvim_del_keymap, mode, key)
  end
end

set_keymaps("", "<C-z>", "<Nop>", opts) -- unset ctrl-z (suspend nvim)
set_keymaps("", "<Space>", "<Nop>", opts) -- unset the space key
vim.g.mapleader = " "

-- Load the mappings for all the modes in the keymaps table above.
for mode, mappings in pairs(keymaps) do
  local opt = mode_opts[mode] or opts
  mode = mode_adapters[mode]
  for key, val in pairs(mappings) do
    set_keymaps(mode, key, val, opt)
  end
end
