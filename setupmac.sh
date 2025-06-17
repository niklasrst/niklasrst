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
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

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

### CONFIGS FOLDER
mkdir -p ~/.config

#################
## FOLDERS
#################
### REPO
mkdir -p ~/repos

#################
## APPS
#################
### HOMEBREW
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /$HOME/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /$HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

### GITCREDMGR
brew install --cask git-credential-manager

### PWSH
brew install --cask powershell

#### PWSH MODULES
### VSCODE
#### In VSCODE search for `Shell Command`

### OhMyPosh
brew install oh-my-posh

### KeePass
brew install --cask keepassxc

### lazygit
brew install lazygit

### superfile
brew install superfile

### WindowsApp
brew install --cask windows-app

#################
## GIT REPOS
#################
### DOTFILES (GITHUB)
git clone --recurse-submodules https://github.com/niklasrst/dotfiles ~/repos/dotfiles
ln -s ~/repos/dotfiles/pwsh ~/.config/powershell
spf -c ~/repos/dotfiles/superfile/config.toml

### DOCS (DEVOPS)
git clone --recurse-submodules https://fraport@dev.azure.com/fraport/FrontEnd-Management/_git/docs ~/repos/docs
