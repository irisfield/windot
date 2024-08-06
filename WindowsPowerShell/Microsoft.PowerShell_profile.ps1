# Environment Variables
$env:PATH += "${env:USERPROFILE}\Documents\PowerShell\Bin;"
$env:GIT_CONFIG_GLOBAL = "${env:LOCALAPPDATA}\git\config"

if (!(Test-Path -Path $env:GIT_CONFIG_GLOBAL)) {
  New-Item -Path $env:GIT_CONFIG_GLOBAL -ItemType File -Force | Out-Null
  Invoke-Expression "git config --global core.pager '""'"
  Invoke-Expression "git config --global core.editor nvim"
  Invoke-Expression "git config --global core.autocrlf false"
  Invoke-Expression "git config --global credential.helper manager"
  Invoke-Expression "git config --global init.defaultBranch master"
  Write-Host "Git config file location set to $($env:GIT_CONFIG_GLOBAL)." -ForegroundColor Blue
}

# Functions
function lf {
  # NOTE: If this function is not working properly,
  # try removing lf from $env:PATH to avoid conflicts.
  $lfcd = "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages\gokcehan.lf_Microsoft.Winget.Source_8wekyb3d8bbwe\lf.exe"
  & $lfcd -print-last-dir $args | Set-Location
}

function vv {
  # edit your file system with neovim
  nvim -c "Dirbuf" # requires the dirbuf.nvim plugin
}

# Aliases
Set-Alias vi nvim

# Git integration
Import-Module posh-git
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $True

####################
# Shell Experience #
####################

# Make the PowerShell experience Unix-like
# https://github.com/PowerShell/PSReadLine

# Zsh-like tab completion
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocomplete commands with arguments from history with the arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Change the cursor depending on the Vi mode
$ESC = "$([char]0x1b)"
$OnViModeChange = [scriptblock] {
  if ($args[0] -eq 'Command') {
    # Set the cursor to a non-blinking block.
    Write-Host -NoNewLine "${ESC}[2 q"
  }
  else {
    # Set the cursor to a non-blinking vertical line.
    Write-Host -NoNewLine "${ESC}[6 q"
  }
}

# The default cursor is a block, set it to a vertical line on startup
Write-Host -NoNewLine "${ESC}[6 q"

# Enable vi mode for PowerShell
Set-PsReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $OnViModeChange

# Use the system clipboard in Vi Mode
Set-PSReadLineKeyHandler -Key 'y' -Function Copy -ViMode Command
Set-PSReadLineKeyHandler -Key 'p' -Function Paste -ViMode Command

# Automatically insert matching quote
Set-PSReadLineKeyHandler -Chord '"',"'" -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($line.Length -gt $cursor -and $line[$cursor] -eq $key.KeyChar) {
  # Just move the cursor
  [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  }
  else {
  # Insert matching quotes, move cursor to be in between the quotes
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
  }
}
