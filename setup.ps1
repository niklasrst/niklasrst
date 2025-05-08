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
Write-Host "Setting wallpaper..." -ForegroundColor Yellow
$url = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg"
$destination = "$env:TEMP\bg.jpg"
Invoke-WebRequest -Uri $url -OutFile $destination

$Data = @{
    WallpaperURL              = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg"
    DownloadDirectory         = "$env:TEMP"
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

# Winget DSC
Write-Host "Apply DSC..." -ForegroundColor Yellow
Function Get-WingetCmd {
    $WingetCmd = $null
    #Get WinGet Path
    try {
        #Get Admin Context Winget Location
        $WingetInfo = (Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe").VersionInfo | Sort-Object -Property FileVersionRaw
        #If multiple versions, pick most recent one
        $WingetCmd = $WingetInfo[-1].FileName
    }
    catch {
        #Get User context Winget Location
        if (Test-Path "$env:LocalAppData\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe") {
            $WingetCmd = "$env:LocalAppData\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe"
        }
    }
    return $WingetCmd
}

if ($null -eq (Get-WingetCmd)) { 
    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name Microsoft.WinGet.Client -Force -Confirm:$false
    Repair-WinGetPackageManager -AllUsers -Force
}

$url = "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/configuration.dsc.yaml"
$destination = "$env:TEMP\configuration.dsc.yaml"
Invoke-WebRequest -Uri $url -OutFile $destination

Start-Process -FilePath "winget.exe" -ArgumentList "configure --enable"
Start-Process -FilePath "winget.exe" -ArgumentList "configure $env:TEMP\configuration.dsc.yaml --accept-configuration-agreements"

# Create symbolic links
Write-Host "Setting symlinks..." -ForegroundColor Yellow
Remove-Item -Path "$ENV:OneDrive\Dokumente\WindowsPowerShell" -Recurse -Force | Out-Null
New-Item -Path "$ENV:OneDrive\Dokumente\WindowsPowerShell" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\pwsh" -Force | Out-Null
Remove-Item -Path "$ENV:OneDrive\Dokumente\PowerShell" -Recurse -Force | Out-Null
New-Item -Path "$ENV:OneDrive\Dokumente\PowerShell" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\pwsh" -Force | Out-Null
New-Item -Path "$ENV:USERPROFILE\.gitconfig" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\.gitconfig" -Force | Out-Null
New-Item -Path "$ENV:USERPROFILE\.gitconfig-azure" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\.gitconfig-azure" -Force | Out-Null
New-Item -Path "$ENV:USERPROFILE\.gitconfig-github" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\.gitconfig-github" -Force | Out-Null
Remove-Item -Path $ENV:LOCALAPPDATA\nvim -Recurse -Force | Out-Null
New-Item -Path "$ENV:LOCALAPPDATA" -Name "nvim" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\nvim" -Force | Out-Null
Remove-Item -Path $ENV:LOCALAPPDATA\superfile -Recurse -Force | Out-Null
New-Item -Path "$ENV:LOCALAPPDATA" -Name "superfile" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\nvim" -Force | Out-Null
Remove-Item -Path $ENV:LOCALAPPDATA\yazi -Recurse -Force | Out-Null
New-Item -Path "$ENV:LOCALAPPDATA" -Name "yazi" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\yazi" -Force | Out-Null
Remove-Item -Path "$ENV:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -Recurse -Force | Out-Null
New-Item -Path "$ENV:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe" -Name "LocalState" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\windowsterminal" -Force | Out-Null
Remove-Item -Path $ENV:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState -Recurse -Force | Out-Null
New-Item -Path "$ENV:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -Name "LocalState" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\winget-config" -Force | Out-Null
New-Item -Path "C:\Data\repos\" -Name "tools" -ItemType SymbolicLink -Value "C:\Data\repos\dotfiles\tools" -Force | Out-Null

# Install nerdfonts
Write-Host "Adding fonts..." -ForegroundColor Yellow
$font_name = "CascadiaCode"
$archive = "$font_name.zip"
$outfile = "$env:TEMP\$archive"
$user_font_dir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$user_font_reg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$archive" -OutFile $outfile

Expand-Archive -Path $outfile -DestinationPath $user_font_dir -Force | Where-Object Name -like "*.ttf" | Foreach-Object {
    New-ItemProperty -Path $user_font_reg -Name $_.Name -Value $_.FullName -PropertyType String -Force | Out-Null
}
Remove-Item -Path $outfile -Force

# Restart
Write-Host "Rebooting..." -ForegroundColor Yellow
Restart-Computer -Delay 30 -Force