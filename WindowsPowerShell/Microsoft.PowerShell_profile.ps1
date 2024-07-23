# Path
# $env:PATH += "${env:USERPROFILE}\Documents\PowerShell\Bin\file-windows"

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
