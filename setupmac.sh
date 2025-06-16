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
IMAGE_URL="https://raw.githubusercontent.com/niklasrst/niklasrst/refs/heads/main/bg.jpg"
IMAGE_PATH="$HOME/Pictures/bg.jpg"
mkdir -p "$HOME/Pictures"
curl -o "$IMAGE_PATH" -L "$IMAGE_URL"
spaces=$(osascript -e 'tell application "System Events" to get the id of every desktop')
for space in $spaces; do
    osascript <<EOD
tell application "System Events"
    tell desktop id $space
        set picture to "$IMAGE_PATH"
    end tell
end tell
EOD
done

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
