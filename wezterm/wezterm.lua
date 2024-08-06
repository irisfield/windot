-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

config.use_ime = true
config.color_scheme = 'Darktooth (base16)'
config.default_prog = { 'powershell.exe', '-NoLogo' }
config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Default window size
config.initial_cols = 110
config.initial_rows = 25

-- WezTerm bundles JetBrains Mono, Nerd Font Symbols and Noto Color Emoji
-- fonts and uses those for the default font configuration.

-- Disable ligatures in most fonts, including JetBrains Mono
-- (https://wezfurlong.org/wezterm/config/font-shaping.html)
 config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- Keybindings
config.keys = {
  -- map lf
  { key = 'o', mods = 'CTRL', action = act{SendString='\x15lf\r'}},
}

-- Return the configuration to wezterm
return config
