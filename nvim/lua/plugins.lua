local plugins = {
  {
    "rebelot/kanagawa.nvim",
    lazy = false, -- load this during startup if it is your main colorscheme
    priority = 1000, -- load this before all the other start plugins
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
  },

  {
    "elihunter173/dirbuf.nvim",
    cmd = {  "Dirbuf" }, -- lazy-load on command
    opts = {
      sort_order = "directories_first",
      write_cmd = "DirbufSync -confirm",
    }
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter", -- lazy-load on event
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-buffer",
      "FelipeLema/cmp-async-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
      local cmp = require("cmp")
      -- needed to ensure super tab works as intended
      local check_backspace = function()
        local col = vim.fn.col(".") - 1
        return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
      end
      -- setup
      cmp.setup({
      mapping = {
          ["<C-y>"] = cmp.config.disable,
          ["<C-j>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
          ["<C-k>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
          ["<C-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          -- super tab
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif check_backspace() then
              fallback()
            else
              fallback()
            end
          end, { "i", "s", }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s", }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer", keyboard_length = 2 },
          { name = "async_path" },
          { name = "nvim_lsp_signature_help" }
        },
        confirm_opts = {
          behavior = cmp.ConfirmBehavior.Replace,
          select = false,
        },
        experimental = {
          ghost_text = true,
          native_menu = false,
        }
      })
    end,
  },

  -- if some code requires a module from an unloaded plugin, it will be automatically loaded.
  -- So for api plugins like devicons, we can always set lazy=true
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = {  "MarkdownPreview" }, -- lazy-load on command
    build = function()
      local download_url = "https://api.github.com/repos/iamcco/markdown-preview.nvim/releases"
      local extract_path = vim.fn.stdpath("data") .. "\\lazy\\markdown-preview.nvim\\app\\bin"
      local ps_script = [[
        # Download zip file to download path
        (Invoke-RestMethod "%s").assets | Where-Object { $_.name -like "*win.zip" } |
        Select-Object -First 1 | ForEach-Object {
          Invoke-WebRequest -Uri $_.browser_download_url -OutFile "${env:TEMP}\mdp-win.zip"
        }

        # Extract zip file to extract path and clean up
        Expand-Archive -Path "${env:TEMP}\mdp-win.zip" -DestinationPath "%s" -Force
        Remove-Item -Path "${env:TEMP}\mdp-win.zip" -Force
      ]]
      local ps_script = string.format(ps_script, download_url, extract_path)

      print "Installing the markdown-preview.nvim binary..."
      local pipe = io.popen("powershell -command -", "w")
      pipe:write(ps_script)
      pipe:close()
      print("markdown-preview-win.exe was installed successfully!")
    end,
  },
}

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup(plugins)
