<#
.SYNOPSIS
    This script downloads a winget dsc file and applies it to the system.

.DESCRIPTION
    This script downloads my winget dsc file and applies it to the system. It also enables the winget configure command.
    The script is intended to be run in a Windows environment and requires administrative privileges.


.EXAMPLE
    Invoke-Expression (Invoke-RestMethod setup.rastcloud.com)
    iex (irm aka.rastcloud.com/setup)

.NOTES
    This script is intended to setup clients for the RAST Cloud environment.

.LINK
    https://github.com/niklasrst/niklasrst

.AUTHOR
    Niklas Rast
#>
#requires -RunAsAdministrator

# Set wallpaper
$url = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg"
$destination = "$env:TEMP\bg.jpg"
Invoke-WebRequest -Uri $url -OutFile $destination

$Data = @{
    WallpaperURL              = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg"
    DownloadDirectory         = "C:\temp"
    RegKeyPath                = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    StatusValue               = "1"
}

$WallpaperDest  = $($Data.DownloadDirectory + "\Wallpaper." + ($Data.WallpaperURL -replace ".*\."))
New-Item -ItemType Directory -Path $Data.DownloadDirectory -ErrorAction SilentlyContinue
Start-BitsTransfer -Source $Data.WallpaperURL -Destination $WallpaperDest
New-Item -Path $Data.RegKeyPath -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImageStatus' -Value $Data.Statusvalue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImagePath' -Value $WallpaperDest -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImageUrl' -Value $WallpaperDest -PropertyType STRING -Force | Out-Null

# Set taskbar layout
$url = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/LayoutModification.xml"
$destination = "$ENV:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"
Invoke-WebRequest -Uri $url -OutFile $destination

# Winget DSC
$url = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/configuration.dsc.yaml"
$destination = "$env:TEMP\configuration.dsc.yaml"
Invoke-WebRequest -Uri $url -OutFile $destination

winget configure --enable
winget configure $env:TEMP\configuration.dsc.yaml --accept-configuration-agreements

# Restart
Restart-Computer -Delay 30 -Force