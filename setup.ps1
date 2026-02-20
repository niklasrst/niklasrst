<#
.SYNOPSIS
    This script downloads a winget dsc file and applies it to the system.

.DESCRIPTION
    This script downloads my winget dsc file and applies it to the system. It also enables the winget configure command.
    The script is intended to be run in a Windows environment and requires administrative privileges.

.EXAMPLE
    Invoke-Expression (Invoke-RestMethod setup.rastcloud.com)
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

# PRE-CHECKS
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name Microsoft.WinGet.Client -Force -Confirm:$false
Repair-WinGetPackageManager -AllUsers -Force

$dotfiles = "C:\Data\repos\dotfiles"
if ($false -eq (Test-Path -Path $dotfiles)) {
    winget install git.git
    Start-Process -FilePath "powershell.exe" -ArgumentList "git clone https://github.com/niklasrst/dotfiles.git $dotfiles" -Wait
}

# APPLY DSC
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Running in Admin mode for SYSTEM configuration."

    ## Winget DSC
    Start-Process -FilePath "winget.exe" -ArgumentList "configure --enable" -Wait
    Start-Process -FilePath "winget.exe" -ArgumentList "configure $dotfiles\client_configuration.dsc.yaml --accept-configuration-agreements" -Wait

    if ($false -eq (Test-Path -Path $dotfiles)) {
        Write-Error "$($dotfiles) not found on $($ENV:COMPUTERNAME)"
        break
    }

    ## Setup symlinks
    $ExcludeUsersList = @("Default", "defaultuser0", "Public")
    foreach ($Folder in Get-ChildItem -Path "C:\Users" -Directory -Exclude $ExcludeUsersList) {
        $user = $Folder.Name

        $configFiles = @{
            "$user\.gitconfig" = "$dotfiles\.gitconfig"
            "$user\.gitconfig-azure" = "$dotfiles\.gitconfig-azure"
            "$user\.gitconfig-github" = "$dotfiles\.gitconfig-github"
            "$([Environment]::GetFolderPath([Environment+SpecialFolder]::Personal))\PowerShell" = "$dotfiles\pwsh\Microsoft.PowerShell_profile.ps1"
            "$([Environment]::GetFolderPath([Environment+SpecialFolder]::Personal))\WindowsPowerShell" = "$dotfiles\pwsh\Microsoft.PowerShell_profile.ps1"
            "C:\Users\$user\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = "$dotfiles\windowsterminal\settings.json"
            "C:\Users\$user\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\state.json" = "$dotfiles\windowsterminal\state.json"
        }

        $configFiles.Keys | Where-Object { Test-Path -Path $_ } | ForEach-Object { Remove-Item -Path $_ -Force }
        $configFiles.Keys | ForEach-Object {
            $null = New-Item -ItemType SymbolicLink -Path $_ -Target $configFiles[$_] -Force
        }
    }

    ## Set wallpaper
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageStatus' -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImagePath' -Value "$dotfiles\bg.jpg" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name 'DesktopImageUrl' -Value "$dotfiles\bg.jpg" -PropertyType STRING -Force | Out-Null

    ## Add PATH variables
    $machine_path = Get-Content -Path "$dotfiles\path_machine.txt"
    [System.Environment]::SetEnvironmentVariable("Path", $machine_path, [System.EnvironmentVariableTarget]::Machine)
    $user_path = $(Get-Content -Path "$dotfiles\path_user.txt") -replace "<home>", $HOME
    [System.Environment]::SetEnvironmentVariable("Path", $user_path, [System.EnvironmentVariableTarget]::User)
} else {
    Write-Output "Running in User mode for customizations."

    ## Winget DSC
    Start-Process -FilePath "winget.exe" -ArgumentList "configure --enable" -Wait
    Start-Process -FilePath "winget.exe" -ArgumentList "configure $dotfiles\user_configuration.dsc.yaml --accept-configuration-agreements" -Wait

    if ($false -eq (Test-Path -Path $dotfiles)) {
        Write-Error "$($dotfiles) not found on $($ENV:COMPUTERNAME)"
        break
    }

    ## Add PATH variables
    $user_path = $(Get-Content -Path "$dotfiles\path_user.txt")
    [System.Environment]::SetEnvironmentVariable("Path", $user_path, [System.EnvironmentVariableTarget]::User) -replace "<home>", $HOME

    ## Add custom startmenu
    Copy-Item -Path "$dotfiles\LayoutModification.xml" -Destination "$env:LOCALAPPDATA\Microsoft\Windows\Shell" -Force
}

do {
    $response = Read-Host "Reboot now? (Y/N)"
} until ($response -match '^[YN]$')
if ($response -eq 'Y') {
    Restart-Computer
}