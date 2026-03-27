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

## Prevent OneDrive Sync for special folders
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO" -Name "1" -Value "PowerShell" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO" -Name "1" -Value "WindowsPowerShell" -PropertyType String -Force | Out-Null

## Setup symlinks
Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    if ($_.Name -notin "defaultuser0", "public", "All Users", "Default") {
        Write-Host "Processing user: $($_.Name)"

        $status = dsregcmd /status | Out-String
        $isManaged = $status -match "AzureAdPrt : YES" -and $status -match "MdmUrl : https://enrollment.manage.microsoft.com"
        if ($true -eq $isManaged) { $docFolder = $ENV:OneDrive\Dokumente } else { $docFolder = "C:\Users\$($_.Name)\Documents" }
 
        $targets = @(
            "$docFolder\WindowsPowerShell",
            "$docFolder\PowerShell",
            "C:\Users\$($_.Name)\.gitconfig",
            "C:\Users\$($_.Name)\.gitconfig-azure",
            "C:\Users\$($_.Name)\.gitconfig-github",
            "C:\Users\$($_.Name)\.gitconfig-github-fraport"
        )

        $targets | ForEach-Object { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }

        New-Item -ItemType SymbolicLink -Path "$docFolder\WindowsPowerShell" -Value "$dotfiles\pwsh"  -Force
        New-Item -ItemType SymbolicLink -Path "$docFolder\PowerShell" -Value "$dotfiles\pwsh" -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig" -Value "$dotfiles\.gitconfig" -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-azure" -Value "$dotfiles\.gitconfig-azure" -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-github" -Value "$dotfiles\.gitconfig-github" -Force
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\.gitconfig-github-fraport" -Value "$dotfiles\.gitconfig-github-fraport" -Force

        Move-Item -Path "C:\Users\$($_.Name)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Destination "C:\Users\$($_.Name)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.org"
        New-Item -ItemType SymbolicLink -Path "C:\Users\$($_.Name)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value "$dotfiles\windowsterminal\settings.json" -Force

        #Get-ChildItem -Path "$docFolder\WindowsPowerShell" -Recurse -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "System" }
        #Get-ChildItem -Path "$docFolder\PowerShell" -Recurse -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "System" }
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





