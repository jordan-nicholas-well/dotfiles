#!/bin/bash
# Personal devcontainer tools — installed automatically via dotfiles repo
# Add any personal tools/config below

sudo apt-get update && sudo apt-get install -y fzf
sudo apt install -y tig


# Install gh 
if ! command -v gh &> /dev/null
then
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
fi


# Set up git authentication with GitHub CLI
gh auth setup-git

# configure git name / email
git config --global user.name "Benjamin Benetti"
git config --global user.email "ben@bbenetti.ca"

# Install editor
./editor-install.sh

# Set default editor to Neovim
export EDITOR=nvim
if ! grep -q 'export EDITOR=nvim' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export EDITOR=nvim' >> "$HOME/.bashrc"
fi
