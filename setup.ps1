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
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg" -OutFile "$env:TEMP\Wallpaper.jpg"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageStatus' -Value "1" -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImagePath' -Value "$env:TEMP\Wallpaper.jpg" -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageUrl' -Value "$env:TEMP\Wallpaper.jpg" -PropertyType STRING -Force | Out-Null

# Start- and Taskbarlayout
Write-Host "Setting Taskbarlayout..." -ForegroundColor Yellow
if (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml") {
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml" -Force
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/LayoutModification.xml" -OutFile "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"

Write-Host "Setting Startlayout..." -ForegroundColor Yellow
if (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.json") {
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.json" -Force
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/LayoutModification.json" -OutFile "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.json"

# Apply Winget DSC
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
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
    Install-Module -Name Microsoft.WinGet.Client -Force -Confirm:$false
    Repair-WinGetPackageManager -AllUsers -Force
}

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/configuration.dsc.yaml" -OutFile "$env:TEMP\configuration.dsc.yaml"
Start-Process -FilePath "winget.exe" -ArgumentList "configure --enable" -Wait
Start-Process -FilePath "winget.exe" -ArgumentList "configure $env:TEMP\configuration.dsc.yaml --accept-configuration-agreements" -Wait

# Clone configs
Write-Host "Cloning git configs..." -ForegroundColor Yellow
if (Test-Path "C:\Data\temp\dotfiles") { Remove-Item -Path "C:\Data\temp\dotfiles" -Recurse -Force | Out-Null}
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"git clone --recurse-submodules https://github.com/niklasrst/dotfiles C:\Data\repos\dotfiles`"" -Wait

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
Restart-Computer -Force