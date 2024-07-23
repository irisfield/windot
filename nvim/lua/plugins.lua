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
require("lazy").setup({
  {
    "rebelot/kanagawa.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
  },

  -- I have a separate config.mappings file where I require which-key.
  -- With lazy the plugin will be automatically loaded when it is required somewhere
  { "folke/which-key.nvim", lazy = true },

  {
    "nvim-neorg/neorg",
    -- lazy-load on filetype
    ft = "norg",
    -- options for neorg. This will automatically call `require("neorg").setup(opts)`
    opts = {
      load = {
        ["core.defaults"] = {},
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
    },
  },

  -- if some code requires a module from an unloaded plugin, it will be automatically loaded.
  -- So for api plugins like devicons, we can always set lazy=true
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- you can use the VeryLazy event for things that can
  -- load later and are not important for the initial UI
  { "stevearc/dressing.nvim", event = "VeryLazy" },

-- install without yarn or npm
  {
      "iamcco/markdown-preview.nvim",
      cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft = { "markdown" },
      build = function()
        local download_url = "https://api.github.com/repos/iamcco/markdown-preview.nvim/releases"
        local extract_path = vim.fn.stdpath("data") .. "\\lazy\\markdown-preview.nvim\\app\\bin"
        local ps_script = [[
          # Download zip file to download path
          Invoke-RestMethod "%s" | ForEach-Object {
              $_.assets | Where-Object { $_.name -like "*win.zip" } | ForEach-Object {
                  Invoke-WebRequest $_.browser_download_url -OutFile "${env:TEMP}\md-preview-win.zip"
              }
          }

          # Create the extraction directory if it does not exist
          if (!(Test-Path -Path "%s")) {
              New-Item -ItemType Directory -Path "%s" | Out-Null
          } else {
          }

          # Extract zip file to extract path
          Expand-Archive -Path "${env:TEMP}\md-preview-win.zip" -DestinationPath "%s" -Force

          # Clean up
          Remove-Item -Path "${env:TEMP}\md-preview-win.zip" -Force
        ]]
        local ps_script = string.format(ps_script, download_url, extract_path, extract_path, extract_path)

        print "Installing the required binary markdown-preview-win.exe..."
        local pipe = io.popen("powershell -command -", "w")
        pipe:write(ps_script)
        pipe:close()
        print "markdown-preview-win.exe was installed successfully!"
        vim.api.nvim_command("messages")
      end,
  },

  -- local plugins can also be configured with the dev option.
  -- This will use {config.dev.path}/noice.nvim/ instead of fetching it from GitHub
  -- With the dev option, you can easily switch between the local and installed version of a plugin
  { "folke/noice.nvim" },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
