
# Environment Variables
# $env:PATH += "${env:USERPROFILE}\Documents\PowerShell\Bin\file-windows"

$env:GIT_CONFIG_GLOBAL = "${env:LOCALAPPDATA}\git\config"

if (!(Test-Path -Path $env:GIT_CONFIG_GLOBAL)) {
  New-Item -Path $env:GIT_CONFIG_GLOBAL -ItemType File -Force | Out-Null
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

# Aliases
Set-Alias vi nvim

# Shortcuts
Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('lf')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
