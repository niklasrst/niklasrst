<#
.SYNOPSIS
    This script downloads a winget dsc file and applies it to the system.

.DESCRIPTION
    This script downloads my winget dsc file and applies it to the system. It also enables the winget configure command.
    The script is intended to be run in a Windows environment and requires administrative privileges.

.EXAMPLE
    Invoke-Expression (Invoke-RestMethod aka.rastcloud.com/setup)
    iex (irm aka.rastcloud.com/setup)

    Update Git submodules
    git pull --recurse-submodules

.NOTES
    This script is intended to setup clients for the RAST Cloud environment.


.LINK
    https://github.com/niklasrst/niklasrst

.AUTHOR
    Niklas Rast
#>
$dotfiles = "C:\Data\repos\dotfiles"

## Winget
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name Microsoft.WinGet.Client -Force -Confirm:$false
Repair-WinGetPackageManager -AllUsers -Force
winget install git.git --source winget --force

## Dotfiles
#cmdkey /list | Select-String "github"
Start-Process "C:\Program Files\Git\cmd\git.exe" -ArgumentList "clone https://github.com/niklasrst/dotfiles.git $($dotfiles)" -Wait -PassThru
Start-Sleep -Seconds 2

## Setup symlinks
Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    if ($_.Name -notin "defaultuser0", "public") {
        Write-Host $_.Name
        New-Item -ItemType SymbolicLink -Path "$ENV:OneDrive\Dokumente\WindowsPowerShell" -Value "$dotfiles\pwsh" -Force
        New-Item -ItemType SymbolicLink -Path "$ENV:OneDrive\Dokumente\PowerShell"  -Name "$dotfiles\pwsh" -Value -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig" -Name "$dotfiles\.gitconfig" -Value -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-azure" -Name "$dotfiles\.gitconfig-azure" -Value -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-github" -Name "$dotfiles\.gitconfig-github" -Value -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-github-fraport" -Name "$dotfiles\.gitconfig-github-fraport" -Value -Force
    }
}

## Install fonts
$fonts = Get-ChildItem -Path "$dotfiles\tools\CascadiaCode" -Filter "*.ttf"
foreach ($font in $fonts) {
    $dest = "C:\Windows\Fonts\$($font.Name)"
    if (!(Test-Path -Path $dest)) {
        Copy-Item -Path $font.FullName -Destination $dest -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $font.BaseName -Value $font.Name -PropertyType STRING -Force | Out-Null
        Write-Output "Installed font: $($font.Name)"
    }
}

## Add PATH variables
$machine_path = Get-Content -Path "$dotfiles\path_machine.txt"
[System.Environment]::SetEnvironmentVariable("Path", $machine_path, [System.EnvironmentVariableTarget]::Machine)
$user_path = $(Get-Content -Path "$dotfiles\path_user.txt") -replace "<home>", $HOME
[System.Environment]::SetEnvironmentVariable("Path", $user_path, [System.EnvironmentVariableTarget]::User)

## Apply DSC configuration
Start-Process -FilePath "winget.exe" -ArgumentList "configure --enable" -Wait -PassThru
Start-Process -FilePath "winget.exe" -ArgumentList "configure $dotfiles\client_configuration.dsc.yaml --accept-configuration-agreements" -Wait -PassThru
Start-Process -FilePath "winget.exe" -ArgumentList "configure $dotfiles\user_configuration.dsc.yaml --accept-configuration-agreements" -Wait -PassThru

## Set wallpaper
#New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Force -ErrorAction SilentlyContinue | Out-Null
#New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageStatus' -Value "1" -PropertyType DWORD -Force | Out-Null
#New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImagePath' -Value "$dotfiles\bg.jpg" -PropertyType STRING -Force | Out-Null
#New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageUrl' -Value "$dotfiles\bg.jpg" -PropertyType STRING -Force | Out-Null

## Register DSC runtime
New-Item -Path "HKLM:\SOFTWARE\WingetDSC" -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\WingetDSC" -Name 'Mode' -Value "FULL" -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\WingetDSC" -Name 'RunAs' -Value "$($ENV:USERNAME)" -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\WingetDSC" -Name 'RunTime' -Value "$((get-date).ToString())" -PropertyType STRING -Force | Out-Null

do {
    $response = Read-Host "Reboot now? (Y/N)"
} until ($response -match '^[YN]$')
if ($response -eq 'Y') {
    Restart-Computer
}

