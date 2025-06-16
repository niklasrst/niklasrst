#SYNOPSIS
# This script downloads a macos dsc file and applies it to the system.

#DESCRIPTION
# This script downloads my macos dsc file and applies it to the system.
# The script is intended to be run in a macOS environment and requires administrative privileges.

#EXAMPLE
# /bin/bash -c "$(curl -fsSL aka.rastcloud.com/setupmac)"

#Update Git submodules
# git pull --recurse-submodules

#NOTES
#This script is intended to setup macos clients for the RAST Cloud environment.

#LINK
#https://github.com/niklasrst/niklasrst

#AUTHOR
#Niklas Rast

#requires -RunAsAdministrator

#################
## CONFIG
#################
### DARKMODE

### WALLPAPER
https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg

#################
## FOLDERS
#################
### REPO

#################
## APPS
#################
### HOMEBREW
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /$HOME/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /$HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

### PWSH
#### PWSH MODULES
### VSCODE
### OhMyPosh
### KeePass
### lazygit

#################
## GIT REPOS
#################
### DOTFILES (GITHUB)
### DOCS (DEVOPS)
