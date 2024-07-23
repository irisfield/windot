If (([Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -ne "S-1-5-32-544") {
    Write-Host "This script requires Administrator privileges. Run from an elevated terminal." -ForegroundColor Yellow
    exit 1
}

### DOTFILES ###

function Ensure-DriveLetter {
    param(
        [string]$Path
    )

    # Check if path already has a drive letter
    if ($Path -match '^[a-zA-Z]:\\') {
        # Return path unchanged if it already has a drive letter
        return $Path
    } else {
        # Add the letter of the home drive if path does not have a drive letter
        return Join-Path -Path $env:HOMEDRIVE -ChildPath $Path
    }
}

function Create-Symlink {
    param(
        [string]$Path, # Path to where you like to create the symbolic link (omit the drive letter)
        [string]$Target # The target the symbolic link points to (omit the drive letter)
    )
    $Path = Ensure-DriveLetter -Path $Path
    $Target = Ensure-DriveLetter -Path $Target

    # Make sure the target exists
    if (!(Test-Path -Path $Target)) {
        Write-Host -NoNewline "Failed to create SymbolicLink for " -ForegroundColor Red
        Write-Host "$($Target)." -ForegroundColor Blue
        Write-Host "Reason: The file or directory does not exist." -ForegroundColor Red
      return
    }

    # Check for existing links
    if (Test-Path -Path $Path) {
      $Item = Get-Item $Path -Force
      if ($Item.LinkType) {
        if ($Item.Target -eq $Target) {
          Write-Host "The $($Item.LinkType) at $($Path) already points to $($Target)." -ForegroundColor Green
          return
        } else {
          Write-Host -NoNewline "A $($Item.LinkType) that points to a different path already exists:`n " -ForegroundColor Yellow
          Write-Host "$($Path) -> $($Item.Target)" -Foreground Blue
          $Message = "Would you like to create a new SymbolicLink to -> $($Target)?"
          $Choices = "&Yes", "&No"
          $Selection = $Host.UI.PromptForChoice("", $Message, $Choices, -1)
          Switch ($Selection) {
            0 { break } # Change the target of the SymbolicLink
            1 { return } # Do not change
          }
        }
      } else {
        Write-Host -NoNewline "Failed to create SymbolicLink for " -ForegroundColor Red
        Write-Host "$($Target)." -ForegroundColor Blue
        Write-Host -NoNewline "Reason: A file or directory already exists at " -ForegroundColor Red
        Write-Host "$($Path)." -ForegroundColor Blue
        return
      }
    }

    try {
      # Attempt to create the symbolic link
      New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
      Write-Host "Created SymbolicLink: $($Path) -> $($Target)" -ForegroundColor Blue
    }
    catch {
      Write-Host "Failed to create SymbolicLink: $($Path) -> $($Target)" -ForegroundColor Red
      Write-Host "Reason: $($_.Exception.Message)"
    }
}

Write-Host "Configuring Symbolic Links..." -ForegroundColor Yellow
Create-Symlink -Path "${env:LOCALAPPDATA}\lf" -Target "${PSScriptRoot}\lf"
Create-Symlink -Path "${env:LOCALAPPDATA}\nvim" -Target "${PSScriptRoot}\nvim"
Create-Symlink -Path "${env:LOCALAPPDATA}\mpv" -Target "${PSScriptRoot}\mpv"
Create-Symlink -Path "${env:APPDATA}\alacritty" -Target "${PSScriptRoot}\alacritty"
Create-Symlink -Path "${env:HOMEPATH}\Documents\PowerToys" -Target "${PSScriptRoot}\PowerToys"
Create-Symlink -Path "${env:HOMEPATH}\Documents\WindowsPowerShell" -Target "${PSScriptRoot}\WindowsPowerShell"
$FirefoxProfile = $(Get-ChildItem "${env:APPDATA}\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -match 'default$' }).FullName
Create-Symlink -Path "${FirefoxProfile}\user.js" -Target "${PSScriptRoot}\firefox\user.js"
Write-Host "Symbolic Links Configured!`n" -ForegroundColor Yellow

$Message = "Would you like run the rest of the script and apply settings and preferences?"
$Choices = "&Yes", "&No"
$Selection = $Host.UI.PromptForChoice("", $Message, $Choices, -1)
Switch ($Selection) {
  0 { break } # Continue running the rest of the script
  1 { exit 1 } # Exit the script
}

### DEPENDENCIES ###

function Install-LatestGithubRelease {
    param(
        [string]$RepoName,
        [string]$DownloadApiUrl,
        [string]$ExtractPath
    )
    $DownloadPath = "${env:TEMP}\${RepoName}.zip"

    Write-Host "Downloading ${RepoName} to ${env:TEMP}..."
    Invoke-RestMethod "$DownloadApiUrl" | ForEach-Object {
        $_.assets | Where-Object { $_.name -like "*win.zip" } | ForEach-Object {
            Invoke-WebRequest $_.browser_download_url -OutFile "$DownloadPath"
        }
    }

    # Create the extraction directory if it does not exist
    if (!(Test-Path -Path "$ExtractPath")) {
        New-Item -ItemType Directory -Path "$ExtractPath" | Out-Null
    }

    Write-Host "Extracting ${RepoName}.zip to ${ExtractPath}..."
    Expand-Archive -Path "$DownloadPath" -DestinationPath "$ExtractPath" -Force

    Write-Host "Cleaning up ${DownloadPath}..."
    Remove-Item -Path "$DownloadPath" -Force
}

# My LF configuration depends on file-windows
$FileRepoName = "file-windows"
$FileDownloadApiUrl = "https://api.github.com/repos/nscaife/${FileRepoName}/releases/latest"
$FileExtractPath = "${env:HOMEPATH}\Documents\PowerShell\Bin\${FileRepoName}"

if (!(Test-Path -Path $FileExtractPath)) {
  Write-Host "Installating dependency ${FileRepoName}:"
  Start-Sleep -Seconds 1
  Install-LatestGithubRelease -RepoName "$FileRepoName" -DownloadApiUrl "$FileDownloadApiUrl" -ExtractPath "$FileExtractPath"
}

$WinUtilDownloadPath = "${env:HOMEPATH}\Downloads\winutil.ps1"
$WinUtilDownloadUrl = "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
if (!(Test-Path -Path $WinUtilDownloadPath)) {
  Write-Host "Downloading the latest version of winutil to ${WinUtilDownloadPath}..."
  Start-Sleep -Seconds 1
  Invoke-WebRequest "$WinUtilDownloadUrl" -OutFile "$WinUtilDownloadPath"
}

### SETTINGS ###

Write-Host "Preferences" -ForegroundColor Yellow

Write-Host "Setting Execution Policy to Unrestricted for ${env:USERNAME}"
# Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
Start-Sleep -Seconds 1

Write-Host "Enabling Developer Mode..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -PropertyType DWORD -Force | Out-Null
Start-Sleep -Seconds 1

Write-Host "Setting hostname to Bluebell..."
Rename-Computer -NewName "Bluebell" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "Adding US-International keyboard layout..."
$LanguageList = Get-WinUserLanguageList
$LanguageList[0].InputMethodTips.Add("0409:00020409")
Start-Sleep -Seconds 1

Write-Host "Deleting the default US keyboard layout..."
$LanguageList[0].InputMethodTips.Remove("0409:00000409") | Out-Null
Start-Sleep -Seconds 1

Write-Host "Adding Japanese keyboard..."
$LanguageList.Add("ja-JP")
$LanguageList[1].Handwriting = $False

Set-WinUserLanguageList -LanguageList $LanguageList -Force
Start-Sleep -Seconds 1

If (Test-Path "Registry::HKU\.DEFAULT\Keyboard Layout\Preload") {
  Write-Host "Preventing Windows from automatically adding back the US keyboard layout..."
  Remove-Item -Path "Registry::HKU\.DEFAULT\Keyboard Layout\Preload" -Force | Out-Null
  Start-Sleep -Seconds 1
}

# Not using this function, but placing here just in case.
function Invoke-WPFUpdatesDisable {
    <#

    .SYNOPSIS
        Disables Windows Update

    .NOTES
        Disabling Windows Update is not recommended. This is only for advanced users who know what they are doing.

    #>
    Write-Host "Disabling Windows Updates..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    $WUServices = @(
        "BITS"
        "wuauserv"
    )

    foreach ($WUService in $WUServices) {
        # -ErrorAction SilentlyContinue is so it does not write an error to stdout if a service does not exist

        Write-Host "Setting ${WUService} StartupType to Disabled"
        Get-Service -Name "$WUService" -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
        Start-Sleep -Seconds 1
    }
    Write-Host "--- UPDATES ARE DISABLED ---" -ForegroundColor Blue
}

function Invoke-WPFUpdatesSecurity {
    <#

    .SYNOPSIS
        Sets Windows Update to recommended settings

    .DESCRIPTION
        1. Disables driver offering through Windows Update
        2. Disables Windows Update automatic restart
        3. Sets Windows Update to Semi-Annual Channel (Targeted)
        4. Defers feature updates for 365 days
        5. Defers quality updates for 4 days

    #>
    Write-Host "Disabling driver offering through Windows Update..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
    Start-Sleep -Seconds 1
    Write-Host "Disabling Windows Update automatic restart..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
    Start-Sleep -Seconds 1
    Write-Host "Disabling driver offering through Windows Update"
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 4
    Write-Host "--- UPDATES SET TO SECURITY ---" -ForegroundColor Blue
    Start-Sleep -Seconds 1
}

function Invoke-DisableSearchSuggestions {
    <#

    .SYNOPSIS
        Disable Search Box Web Suggestions in Registry (explorer restart)

    .DESCRIPTION
        Disables web suggestions when searching using Windows Search.

    #>
    Write-Host "Disabling Search Box Web Suggestions in Windows Search..."
    If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
          New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
    }
    New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 1 -Force | Out-Null
    Stop-Process -name explorer -force
    Start-Sleep -Seconds 1
}

Function Invoke-WindowsDarkMode {
    <#

    .SYNOPSIS
        Enables Dark Mode

    #>
    Try{
        Write-Host "Enabling Dark Mode..."
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty -Path "$Path" -Name AppsUseLightTheme -Value 0 | Out-Null
        Set-ItemProperty -Path "$Path" -Name SystemUsesLightTheme -Value 0 | Out-Null
        Start-Sleep -Seconds 1
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set ${Path}\${Name} to ${Value} due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set ${Name} due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}

function Invoke-ApplyRecommendedTweaks {
    <#

    .SYNOPSIS
        Apply all my preferred settings and preferences.

    #>

    Write-Host "Setting BIOS time to UTC (fixes time sync issues with Linux Systems)..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord
    Start-Sleep -Seconds 1

    Write-Host "Disabling Hibernation..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Type Dword -Value 0
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings") {
      Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0
    }
    Start-Sleep -Seconds 1

    Write-Host "Disabling Fast Startup..."
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name "HiberbootEnabled" -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling User Account Control (UAC) prompt..."
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Changing Wallpaper..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value "${env:SystemRoot}\Web\Wallpaper\ThemeA\img20.jpg"
    Start-Sleep -Seconds 1

    Write-Host "Disabling Sticky Keys..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 506 -Type DWord
    Start-Sleep -Seconds 1

    Write-Host "Deleting temporary files..."
    Get-ChildItem -Path "C:\Windows\Temp" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path "$env:TEMP" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Write-Host "--- TELEMETRY AND TRACKING ---" -ForegroundColor Blue

    Write-Host "Disabling Telemetry..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling Wi-Fi Sense"
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling Application suggestions..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
        Write-Host "Disabling Cloud Content..."
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    Write-Host "Disabling Activity History..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0
    Start-Sleep -Seconds 1


    Write-Host "Disable Location Tracking..."
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location") {
        # Uncomment everything to disable location tracking in absolute.
        # I do not want to disable it completely because it is useful for automatic timezone update.
        # Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Deny"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling automatic Maps updates..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling Feedback..."
    if (Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules") {
        Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
    Start-Sleep -Seconds 1

    if (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
        Write-Host "Disabling Tailored Experiences..."
        Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo") {
        Write-Host "Disabling Advertising ID..."
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Recurse -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    Write-Host "Disabling Error reporting..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1
    Start-Sleep -Seconds 1

    Write-Host "Disabling Storage Sense..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type Dword -Force
    Start-Sleep -Seconds 1

    Write-Host "--- TELEMETRY AND TRACKING DISABLED SUCCESSFULLY ---" -ForegroundColor Blue

    Write-Host "Changing default Explorer view to This PC..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1
    Start-Sleep -Seconds 1

    Write-Host "Enabling showing file extensions"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disabling Task View button..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0
    Start-Sleep -Seconds 1

    Write-Host "Disable News and Interests"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
    # Remove "News and Interest" from taskbar
    Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 0
    Start-Sleep -Seconds 1
}

Invoke-WindowsDarkMode
Invoke-WPFUpdatesSecurity
Invoke-DisableSearchSuggestions
Invoke-ApplyRecommendedTweaks
Start-Sleep -Seconds 1

$WinGetPackageIds = @(
    "Git.Git"
    "7zip.7zip"
    "gokcehan.lf"
    "Neovim.Neovim"
    "ShareX.ShareX"
    "IDRIX.VeraCrypt"
    "Mozilla.Firefox"
    "Alacritty.Alacritty"
    "Microsoft.PowerToys"
    "rjpcomputing.luaforwindows" # needed for my neovim config
    "DEVCOM.JetBrainsMonoNerdFont"
)

Write-Host "--- PACKAGES ---" -ForegroundColor Blue
foreach ($PackageId in $WinGetPackageIds) {
  Write-Host "Installing ${PackageId}..." -ForegroundColor Yellow
  winget install --id $PackageId
}

Write-Host "Script configurations applied. Restart for changes to take effect." -ForegroundColor Yellow
Write-Host "Finishing Steps:" -ForegroundColor Green
Write-Host "1. Run winutil" -ForegroundColor Green
Write-Host "2. In winutil, click the settings cog and import: ${PSScriptRoot}\winutil_settings.json." -ForegroundColor Green
Write-Host "3. Apply all selected items imported from winutil_setttings.json." -ForegroundColor Green
Write-Host "4. Lastly, negivate to the Tweaks tab, and 'Run OO Shutup'." -ForegroundColor Green
Write-Host "5. In OO Shutup, apply all recommended settings." -ForegroundColor Green
Write-Host "Path: ${WinUtilDownloadPath}" -ForegroundColor Green

Write-Host "Launching winutil in 8 seconds..."
Start-Sleep -Seconds 8
Start-Process powershell.exe -ArgumentList "-File $WinUtilDownloadPath -Verb RunAs"
