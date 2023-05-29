# SPDX-License-Identifier: BSD-2-Clause
# Copyright (C) 2023 Dimitar Yurukov <mscalindt@protonmail.com>
$ErrorActionPreference = "SilentlyContinue"
$PC_Name = 'DESKTOP-M533IA'

function Install-App($appName, $appPath, $appUrl) {
    if ([string]::IsNullOrEmpty($appName) -or [string]::IsNullOrEmpty($appPath) -or [string]::IsNullOrEmpty($appUrl)) {
        throw "One or more parameters are null or empty."
    }

    if (Test-Path $appPath) {
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "``$appName`` is already installed."
    } else {
        Write-Host -NoNewline "> " -ForegroundColor White
        Write-Host "Installing ``$appName``..."

        $out = "$env:TEMP\$appName" + "Setup.exe"

        try {
            Invoke-WebRequest -Uri $appUrl -OutFile $out
            Start-Process -FilePath $out -Wait -PassThru
        } catch {
            Write-Host -NoNewline "> " -ForegroundColor Red
            Write-Host "Error occurred while installing ``$appName``. Error: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
   A function to remove scheduled tasks that match a specified pattern.

.DESCRIPTION
   The Remove-Task function uses the Get-ScheduledTask cmdlet to find tasks
   whose names match a specified pattern. It then removes these tasks using
   the Unregister-ScheduledTask cmdlet.

.PARAMETER TaskPattern
   A string that specifies the pattern to match against task names.
   This pattern can include wildcards.

.EXAMPLE
   Remove-Task -TaskPattern "examplePattern"
   Removes all tasks whose names contain the string "examplePattern".

.NOTES
   You might need elevated permissions to run this function. If you encounter
   permission issues, try running PowerShell as an administrator.
   Be very careful when using wildcards, as you could unintentionally match
   and delete tasks you did not intend to.
#>
function Remove-Task {
    param (
        [Parameter(Mandatory=$true)]
        [string] $TaskPattern
    )

    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*$TaskPattern*" }

    if ($tasks -eq $null) {
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "No match: ``$TaskPattern``."
    }

    foreach ($task in $tasks) {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
        Write-Host -NoNewline "> " -ForegroundColor White
        Write-Host "``$($task.TaskName)`` successfully removed."
    }
}

<#
.SYNOPSIS
    A function to remove a Windows Capability.

.DESCRIPTION
    This function takes a pattern as a parameter, searches for a Windows Capability that matches this pattern,
    checks if the capability is currently installed, and if it is, removes it.

.PARAMETER CapPattern
    The pattern of the capability to remove.

.EXAMPLE
    Remove-WindowsCap -CapPattern "QuickAssist"
#>
function Remove-WindowsCap {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CapPattern
    )

    $Capability = Get-WindowsCapability -Online | Where-Object {$_.Name -like "*$CapPattern*" -and $_.State -eq 'Installed'}

    if ($Capability) {
        $Result = Remove-WindowsCapability -Online -Name $Capability.Name

        if ($Result) {
            Write-Host -NoNewline "> " -ForegroundColor White
            Write-Host "``$($Capability.Name)`` successfully removed."
        } else {
            Write-Host -NoNewline "> " -ForegroundColor Red
            Write-Host "Failed to remove capability ``$($Capability.Name)``."
        }
    } else {
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "``$CapPattern`` capability is not installed."
    }
}

<#
.SYNOPSIS
    A function to disable a Windows Optional Feature.

.DESCRIPTION
    This function takes a pattern as a parameter, searches for a Windows Optional Feature that matches this pattern,
    checks if the feature is currently enabled, and if it is, disables it.

.PARAMETER FeaturePattern
    The pattern of the feature name to be disabled.

.EXAMPLE
    Remove-WindowsOptionalFeature -FeaturePattern "Internet*Explorer"
#>
function Remove-WindowsOptionalFeature {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeaturePattern
    )

    $Feature = Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*$FeaturePattern*"}

    if ($Feature) {
        $FeatureName = $Feature.FeatureName

        if($Feature.State -eq 'Enabled') {
            Write-Host -NoNewline "> " -ForegroundColor White
            Write-Host "Disabling ``$FeatureName``..."
            Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName
        } else {
            Write-Host -NoNewline "> " -ForegroundColor Green
            Write-Host "``$FeatureName`` feature is already disabled."
        }
    } else {
        Write-Host -NoNewline "> " -ForegroundColor Yellow
        Write-Host "Failed to match feature ``$FeaturePattern``."
    }
}

<#
.SYNOPSIS
   A function to rename the PC in Windows 10.

.DESCRIPTION
   The Set-PCName function changes the name of the PC to the name specified in the $NewName parameter.
   It first checks if the new name is valid (must be 15 characters or less and contain only alphanumeric characters and hyphens).
   Then, it retrieves the current PC name and checks if it's the same as the new name.
   If it is not, it attempts to rename the PC, and if successful, outputs a success message. If there's an error during renaming, it writes an error message.
   If the new name is the same as the current name, it outputs a message with the current name.
   If the new name is not valid, it writes an error message indicating the validity rules.

.PARAMETER NewName
   The new name that the PC should be renamed to.

.EXAMPLE
   Set-PCName -NewName "NewPCName"
   Changes the PC name to "NewPCName" if it's valid and not the same as the current PC name.

.INPUTS
   System.String
   You can pipe a string that you want to set as the new PC name to Set-PCName.

.OUTPUTS
   None. This function does not produce any output.
#>
function Set-PCName {
    param (
        [Parameter(Mandatory=$true)]
        [string]$NewName
    )

    # Checking if the new name is valid (less than or equal to 15 characters, no special characters).
    if ($NewName.Length -le 15 -and $NewName -match '^[a-zA-Z0-9-]*$') {

        $CurrentName = (Get-WmiObject -Class Win32_ComputerSystem).Name

        if ($CurrentName -ne $NewName) {
            try {
                Rename-Computer -NewName $NewName -ErrorAction Stop
                Write-Host -NoNewline "> " -ForegroundColor White
                Write-Host "PC renamed successfully: $CurrentName -> $NewName"
            } catch {
                Write-Host -NoNewline "> " -ForegroundColor Red
                Write-Error "There was an error while renaming the PC: $_"
            }
        } else {
            Write-Host -NoNewline "> " -ForegroundColor Green
            Write-Host "PC name: $CurrentName"
        }
    } else {
        Write-Host -NoNewline "> " -ForegroundColor Red
        Write-Error "The specified PC name ``$NewName`` is invalid. It should be no more than 15 characters and can only contain letters, numbers, and hyphens"
    }
}

function UnpinFromTaskbar ($AppName) {
    try {
        $SHELL = New-Object -ComObject Shell.Application
        $DIR = $SHELL.Namespace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}')
        $APP = $DIR.Items() | Where-Object { $_.Name -eq $AppName }

        if ($null -eq $APP) {
            return
        }

        $unpinVerb = $APP.Verbs() | Where-Object { $_.Name -eq 'Unpin from Tas&kbar' }

        if ($null -eq $unpinVerb) {
            return
        }

        $unpinVerb | ForEach-Object { $_.DoIt() }
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "``$AppName`` unpinned."
    } catch {
        Write-Host -NoNewline "> " -ForegroundColor Red
        Write-Host "Error occurred while unpinning ``$AppName``. Error: $($_.Exception.Message)"
    }
}

Write-Host ">> mscalindt:"
Write-Host ""

$FF_PATH = "C:\Program Files\Mozilla Firefox\firefox.exe"
$STEAM_PATH = "C:\Program Files (x86)\Steam\Steam.exe"
$TELEGRAM_PATH = "$env:USERPROFILE\AppData\Roaming\Telegram Desktop\Telegram.exe"

$FF_URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
$STEAM_URL = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
$TELEGRAM_URL = "https://telegram.org/dl/desktop/win64"

Install-App "Firefox" $FF_PATH $FF_URL
Install-App "Steam" $STEAM_PATH $STEAM_URL
Install-App "Telegram" $TELEGRAM_PATH $TELEGRAM_URL

Write-Host ""
Write-Host ">> To remove Microsoft bloatware..."
Write-Host ""

$MS_appBloat = @(
    "Disney",
    "Microsoft.Getstarted",
    "Microsoft.Xbox",
    "MicrosoftOfficeHub",
    "MicrosoftStickyNotes",
    "MixedReality",
    "SpotifyMusic",
    "windowscommunicationsapps",
    "WindowsFeedbackHub",
    "ZuneMusic"
)
$MS_appBloat = $MS_appBloat | Sort-Object

$MS_appBloatExcluded = @(
    "Microsoft.XboxGameCallableUI"
)
$MS_appBloatExcluded = $MS_appBloatExcluded | Sort-Object

foreach ($appName in $MS_appBloat) {
    $matchedApps = Get-AppxPackage | Where-Object { $_.Name -like "*$appName*" }

    if ($matchedApps) {
        foreach ($matchedApp in $matchedApps) {
            $appPackageFullName = $matchedApp.PackageFullName

            # Extract the package name using regular expression.
            $packageName = $appPackageFullName -replace "_.*$"

            if ($packageName -ne $null -and $MS_appBloatExcluded -notcontains $packageName) {
                Write-Host -NoNewline "> " -ForegroundColor White
                Write-Host "> Removing ``$appPackageFullName``..."

                Remove-AppxPackage -Package $appPackageFullName
            } else {
                Write-Host -NoNewline "> " -ForegroundColor Yellow
                Write-Host "Skipped ``$appPackageFullName``."
            }
        }
    } else {
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "``$appName`` not matched/installed."
    }
}

# Additional step to remove OneDrive.
$ONEDRIVE_Setup = Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe"
$ONEDRIVE_Dir = Join-Path $env:USERPROFILE "OneDrive"
if (Test-Path $ONEDRIVE_Dir) {
    Write-Host -NoNewline "> " -ForegroundColor White
    Write-Host "Removing ``OneDrive``..."

    Start-Process -FilePath $ONEDRIVE_Setup -ArgumentList "/uninstall" -Wait
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "rd /s /q `"$ONEDRIVE_Dir`"" -NoNewWindow -Wait
} else {
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "``OneDrive`` is not installed."
}

# Notify for Microsoft Health Update Tools.
$CAPABILITY_Name = "Client.RefreshApps"
$CAPABILITY = Get-WindowsCapability -Online | Where-Object { $_.Name -like "*$capabilityName*" }
if ($CAPABILITY) {
    Write-Host -NoNewline "> " -ForegroundColor Yellow
    Write-Host "Skipped ``Microsoft Health Update Tools``."
} else {
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "``Microsoft Health Update Tools`` is not installed."
}

Write-Host ""
Write-Host ">> To disable/remove bloatware features..."
Write-Host ""

# Disable/Remove Internet Explorer 11.
Remove-WindowsOptionalFeature -FeaturePattern "Internet*Explorer"
Remove-WindowsCap -CapPattern "InternetExplorer"
# Remove Microsoft Quick Assist.
Remove-WindowsCap -CapPattern "QuickAssist"
# Remove Windows Fax and Scan.
Remove-WindowsCap -CapPattern "Fax.Scan"
# Remove Windows Hello Face.
Remove-WindowsCap -CapPattern "Hello.Face"
# Remove WordPad.
Remove-WindowsCap -CapPattern "Windows.WordPad"

Write-Host ""
Write-Host ">> To remove bloatware tasks..."
Write-Host ""

# MicrosoftEdgeUpdateTask...
Remove-Task -TaskPattern "MicrosoftEdgeUpdateTask"
# OneDrive Reporting Task...
Remove-Task -TaskPattern "OneDrive*Reporting"
# Flighting / Windows Insider Program
Remove-Task -TaskPattern "UsageData"
Remove-Task -TaskPattern "RefreshCache"

Write-Host ""
Write-Host ">> To disable bad Windows Defender settings..."
Write-Host ""

$CUR_Prefs = Get-MpPreference
$PREFS_Changed = $false
$SMARTSCREEN_Flag = $false
if ($CUR_Prefs.SubmitSamplesConsent -ne 2) {
    Set-MpPreference -SubmitSamplesConsent 2
    Write-Host -NoNewline "> " -ForegroundColor White
    Write-Host "`Automatic sample submission` disabled."
    $PREFS_Changed = $true
}
if ($CUR_Prefs.MAPSReporting -ne 0) {
    Set-MpPreference -MAPSReporting 0
    Write-Host -NoNewline "> " -ForegroundColor White
    Write-Host "`Cloud-delivered protection` disabled."
    $PREFS_Changed = $true
}
$REG_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
$REG_Prop = Get-ItemProperty -Path $REG_Path -ErrorAction SilentlyContinue
if (($null -eq $REG_Prop.SmartScreenEnabled) -or ($REG_Prop.SmartScreenEnabled -ne 'Off')) {
    Set-ItemProperty -Path $REG_Path -Name 'SmartScreenEnabled' -Value 'Off'
    if ($SMARTSCREEN_Flag -eq $false) {
        Write-Host -NoNewline "> " -ForegroundColor White
        Write-Host "`SmartScreen` disabled."
        $SMARTSCREEN_Flag = $true
    }
    $PREFS_Changed = $true
}
$REG_Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$REG_Prop = Get-ItemProperty -Path $REG_Path -ErrorAction SilentlyContinue
if (($null -eq $REG_Prop.EnableSmartScreen) -or ($REG_Prop.EnableSmartScreen -ne 0)) {
    Set-ItemProperty -Path $REG_Path -Name 'EnableSmartScreen' -Value 0
    if ($SMARTSCREEN_Flag -eq $false) {
        Write-Host -NoNewline "> " -ForegroundColor White
        Write-Host "`SmartScreen` disabled."
        $SMARTSCREEN_Flag = $true
    }
    $PREFS_Changed = $true
}
if ($PREFS_Changed -eq $false) {
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "All settings are good!"
}

Write-Host ""
Write-Host ">> To perform various system operations..."
Write-Host ""

# Change system theme to Dark.
try {
    $REG_Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'SystemUsesLightTheme' -ErrorAction Stop

    if ($CURRENT_Value.SystemUsesLightTheme -ne 0) {
        Set-ItemProperty -Path $REG_Path -Name "SystemUsesLightTheme" -Value 0
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "System theme set to Dark for current user."
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'SystemUsesLightTheme' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "System theme set to Dark for current user."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to change system theme to Dark for current user."
}
try {
    $REG_Path = 'HKU:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    if (Test-Path -Path $REG_Path) {
        $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'SystemUsesLightTheme' -ErrorAction Stop

        if ($CURRENT_Value.SystemUsesLightTheme -ne 0) {
            Set-ItemProperty -Path $REG_Path -Name "SystemUsesLightTheme" -Value 0
            Write-Host -NoNewline "> " -ForegroundColor Green
            Write-Host "System theme set to Dark for Default user (login screen)."
        }
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'SystemUsesLightTheme' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "System theme set to Dark for Default user (login screen)."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to change system theme to Dark for Default user (login screen)."
}

# Change app theme to Dark.
try {
    $REG_Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'AppsUseLightTheme' -ErrorAction Stop

    if ($CURRENT_Value.AppsUseLightTheme -ne 0) {
        Set-ItemProperty -Path $REG_Path -Name "AppsUseLightTheme" -Value 0
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "App theme set to Dark for current user."
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'AppsUseLightTheme' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "App theme set to Dark for current user."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to change app theme to Dark for current user."
}
try {
    $REG_Path = 'HKU:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (Test-Path -Path $REG_Path) {
        $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'AppsUseLightTheme' -ErrorAction Stop

        if ($CURRENT_Value.AppsUseLightTheme -ne 0) {
            Set-ItemProperty -Path $REG_Path -Name "AppsUseLightTheme" -Value 0
            Write-Host -NoNewline "> " -ForegroundColor Green
            Write-Host "App theme set to Dark for Default user (login screen)."
        }
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'AppsUseLightTheme' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "App theme set to Dark for Default user (login screen)."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to change app theme to Dark for Default user (login screen)."
}

# Disable Transparency Effects.
try {
    $REG_Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'EnableTransparency' -ErrorAction Stop

    if ($CURRENT_Value.EnableTransparency -ne 0) {
        Set-ItemProperty -Path $REG_Path -Name "EnableTransparency" -Value 0
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "Disabled Transparency Effects for current user."
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'EnableTransparency' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "Disabled Transparency Effects for current user."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to disable Transparency Effects for current user."
}
try {
    $REG_Path = 'HKU:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (Test-Path -Path $REG_Path) {
        $CURRENT_Value = Get-ItemProperty -Path $REG_Path -Name 'EnableTransparency' -ErrorAction Stop

        if ($CURRENT_Value.EnableTransparency -ne 0) {
            Set-ItemProperty -Path $REG_Path -Name "EnableTransparency" -Value 0
            Write-Host -NoNewline "> " -ForegroundColor Green
            Write-Host "Disabled Transparency Effects for Default user (login screen)."
        }
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $REG_Path -Name 'EnableTransparency' -Value 0
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "Disabled Transparency Effects for Default user (login screen)."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to disable Transparency Effects for Default user (login screen)."
}

# Change the desktop background to a solid dark gray.
$HEX_Color = '29282E'
try {
    $regPath = 'HKCU:\Control Panel\Colors'
    $currentColor = Get-ItemProperty -Path $regPath -Name 'Background' -ErrorAction Stop

    if ($currentColor.Background -ne $HEX_Color) {
        Set-ItemProperty -Path $regPath -Name 'Background' -Value "$HEX_Color"
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "Changed the desktop background to solid dark gray."
    }
} catch [System.Management.Automation.PSArgumentException] {
    Set-ItemProperty -Path $regPath -Name 'Background' -Value "$HEX_Color"
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "Changed the desktop background to solid dark gray."
} catch {
    Write-Host -NoNewline "> " -ForegroundColor Red
    Write-Warning -Message "Failed to change the desktop background."
}
# Create a dummy image; required.
$DUMMY_ImgPath = "$env:USERPROFILE\Pictures\mscalindt_dummy.bmp"
$DUMMY_Img = [System.Drawing.Bitmap]::new(1, 1)
$DUMMY_Img.SetPixel(0, 0, [System.Drawing.ColorTranslator]::FromHtml("#$HEX_Color"))
$DUMMY_Img.Save($DUMMY_ImgPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
# Use the dummy image.
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
# Variable to supress the return code from being printed.
$DUMMY_Result = [Wallpaper]::SystemParametersInfo(20, 0, "$env:USERPROFILE\Pictures\mscalindt_dummy.bmp", 3)
# Remove the dummy image.
if (Test-Path -Path $DUMMY_ImgPath) {
    Remove-Item -Path $DUMMY_ImgPath -Force
}

# Disable Edge's auto-startup.
$REG_Path1 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}\Commands\on-logon-autolaunch'
$REG_Path2 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}\Commands\on-logon-startup-boost'
$Flag = $false
foreach ($Path in $REG_Path1, $REG_Path2) {
    if (Test-Path $Path) {
        $REG_Prop = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
        if ($null -eq $REG_Prop.AutoRunOnLogon -or $REG_Prop.AutoRunOnLogon -ne 0) {
            Set-ItemProperty -Path $Path -Name "AutoRunOnLogon" -Value 0 -Force
            $Flag = $true
        }
    }
}
if ($Flag) {
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "Disabled Edge's auto-startup."
}

# Disable Edge's preloading.
$REG_Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
if (-not(Test-Path $REG_Path)) {
    New-Item -Path $REG_Path -Force | Out-Null

    $REG_Prop = Get-ItemProperty -Path $REG_Path -ErrorAction SilentlyContinue
    if ($null -eq $REG_Prop.StartupBoostEnabled -or $REG_Prop.StartupBoostEnabled -ne 0) {
        Set-ItemProperty -Path $REG_Path -Name "StartupBoostEnabled" -Value 0 -Force
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "Disabled Edge's preload (Startup Boost)."
    }
}

# Disable Background Apps.
$REG_Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
$REG_Prop = Get-ItemProperty -Path $REG_Path -ErrorAction SilentlyContinue
if ($null -eq $REG_Prop.GlobalUserDisabled -or $REG_Prop.GlobalUserDisabled -ne 1) {
    Set-ItemProperty -Path $REG_Path -Name "GlobalUserDisabled" -Value 1 -Force
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "Background Apps disabled."
}

# Set system clock to UTC.
$UTC_Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
$UTC_Key = 'RealTimeIsUniversal'
$UTC_Value = Get-ItemProperty -Path $UTC_Path -Name $UTC_Key -ErrorAction SilentlyContinue
if ($null -eq $UTC_Value.$UTC_Key -or $UTC_Value.$UTC_Key -ne 1) {
    Write-Host -NoNewline "> " -ForegroundColor White
    Write-Host "Will set the system clock to UTC."

    Set-ItemProperty -Path $UTC_Path -Name $UTC_Key -Value 1 -Type DWord
} else {
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "The system clock is already set to UTC!"
}

# Remove Meet Now from the taskbar.
$REG_Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not(Test-Path $REG_Path)) {
    New-Item -Path $REG_Path -Force | Out-Null

    $REG_Prop = Get-ItemProperty -Path $REG_Path -ErrorAction SilentlyContinue
    if ($null -eq $REG_Prop.HideSCAMeetNow -or $REG_Prop.HideSCAMeetNow -ne 1) {
        Set-ItemProperty -Path $REG_Path -Name "HideSCAMeetNow" -Value 1 -Force
        Write-Host -NoNewline "> " -ForegroundColor Green
        Write-Host "``Meet Now`` unpinned."
    }
}

UnpinFromTaskbar 'Microsoft Store'
UnpinFromTaskbar 'Microsoft Edge'

# Remove Microsoft Edge from the desktop.
$EDGE_IconPath = "$env:USERPROFILE\Desktop\Microsoft Edge.lnk"
if (Test-Path -Path $EDGE_IconPath) {
    Remove-Item -Path $EDGE_IconPath -Force
    Write-Host -NoNewline "> " -ForegroundColor Green
    Write-Host "``Microsoft Edge`` icon removed from desktop."
}

# Stop the Explorer process for all changes to take place;
# Windows will automatically restart the process.
Write-Host ""
Write-Host -NoNewline "> " -ForegroundColor White
Write-Host "Restarting ``explorer.exe``..."
Stop-Process -Name explorer -Force

# Set specified PC name.
Write-Host ""
Set-PCName -NewName $PC_Name

Write-Host ""
Write-Host ">> Done!"
