#!/usr/bin/env bash
# Terminal toolkit: Neovim + LazyVim, lazygit, JetBrainsMono Nerd Font
set -euo pipefail

# ===========================================
# Detect package manager
# ===========================================

detect_pm() {
  if command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v brew &>/dev/null; then
    echo "brew"
  else
    echo "unknown"
  fi
}

PM=$(detect_pm)
echo "Detected package manager: $PM"

# ===========================================
# System dependencies
# ===========================================

install_system_deps() {
  case "$PM" in
  dnf)
    sudo dnf install -y curl tar fontconfig git gcc ripgrep gh
    ;;
  apt)
    sudo apt-get update
    sudo apt-get install -y curl tar fontconfig git gcc ripgrep gh
    ;;
  pacman)
    sudo pacman -Sy --noconfirm curl tar fontconfig git gcc ripgrep github-cli
    ;;
  brew)
    brew install curl git gcc ripgrep gh
    ;;
  esac
}

echo "Installing system dependencies..."
install_system_deps

# ===========================================
# Neovim
# ===========================================

install_neovim() {
  if command -v nvim &>/dev/null; then
    echo "Neovim already installed: $(nvim --version | head -1)"
    return
  fi

  case "$PM" in
  dnf)
    sudo dnf install -y neovim
    ;;
  apt)
    # apt often has an old version — use the tarball
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    curl -sL "$nvim_url" -o /tmp/nvim.tar.gz
    sudo tar xzf /tmp/nvim.tar.gz -C /opt
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm /tmp/nvim.tar.gz
    ;;
  pacman)
    sudo pacman -S --noconfirm neovim
    ;;
  brew)
    brew install neovim
    ;;
  esac
  echo "Neovim installed: $(nvim --version | head -1)"
}

echo "Installing Neovim..."
install_neovim

# ===========================================
# LazyVim
# ===========================================

install_lazyvim() {
  if [ -d "$HOME/.config/nvim/lua/plugins" ]; then
    echo "Neovim config already exists at ~/.config/nvim — skipping LazyVim"
    return
  fi

  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
  echo "LazyVim starter installed"
}

install_tree_sitter_cli() {
  # LazyVim's treesitter build hook races with Mason when tree-sitter-cli
  # isn't already on PATH. Pre-install it so `ensure_treesitter_cli`
  # short-circuits and never calls Mason.
  if command -v tree-sitter &>/dev/null; then
    echo "tree-sitter CLI already installed: $(tree-sitter --version)"
    return
  fi

  local arch
  case "$(uname -m)" in
  x86_64) arch="x64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *)
    echo "Unsupported arch for tree-sitter CLI prebuilt: $(uname -m) — skipping"
    return
    ;;
  esac

  # Pinned: v0.26.x is built against glibc 2.39, which breaks on Ubuntu 22.04
  # (glibc 2.35) devcontainers. v0.25.10 is the last release built for glibc 2.34.
  local version="v0.25.10"
  local url="https://github.com/tree-sitter/tree-sitter/releases/download/${version}/tree-sitter-linux-${arch}.gz"
  curl -sL "$url" -o /tmp/tree-sitter.gz
  gunzip -f /tmp/tree-sitter.gz
  chmod +x /tmp/tree-sitter
  sudo mv /tmp/tree-sitter /usr/local/bin/tree-sitter
  echo "tree-sitter CLI installed: $(tree-sitter --version)"
}

install_octo_plugin_spec() {
  local plugins_dir="$HOME/.config/nvim/lua/plugins"
  mkdir -p "$plugins_dir"
  cat >"$plugins_dir/octo.lua" <<'LUA'
return {
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    opts = {
      picker = "snacks",
      use_local_fs = true,
    },
  },
}
LUA
  echo "Wrote octo.nvim plugin spec to $plugins_dir/octo.lua"
}

install_lazyvim_plugins() {
  echo "Installing LazyVim plugins (headless)..."
  nvim --headless "+Lazy! sync" +qa
  echo "LazyVim plugins installed"
}

echo "Setting up LazyVim..."
install_lazyvim
install_tree_sitter_cli
install_octo_plugin_spec
install_lazyvim_plugins

# ===========================================
# lazygit
# ===========================================

install_lazygit() {
  if command -v lazygit &>/dev/null; then
    echo "lazygit already installed: $(lazygit --version | grep -oP 'version=\K[^,]+')"
    return
  fi

  case "$PM" in
  dnf)
    sudo dnf copr enable -y atim/lazygit
    sudo dnf install -y lazygit
    ;;
  apt)
    local version
    version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
    curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz" -o /tmp/lazygit.tar.gz
    sudo tar xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
    rm /tmp/lazygit.tar.gz
    ;;
  pacman)
    sudo pacman -S --noconfirm lazygit
    ;;
  brew)
    brew install lazygit
    ;;
  esac
  echo "lazygit installed"
}

echo "Installing lazygit..."
install_lazygit

# ===========================================
# JetBrainsMono Nerd Font
# ===========================================

install_nerd_font() {
  if fc-list 2>/dev/null | grep -qi "JetBrains.*Nerd"; then
    echo "JetBrainsMono Nerd Font already installed"
    return
  fi

  case "$PM" in
  dnf)
    sudo dnf install -y jetbrains-mono-nl-nerd-fonts
    ;;
  brew)
    brew install --cask font-jetbrains-mono-nerd-font
    ;;
  *)
    mkdir -p "$HOME/.local/share/fonts"
    curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o /tmp/JetBrainsMono.tar.xz
    tar xf /tmp/JetBrainsMono.tar.xz -C "$HOME/.local/share/fonts"
    fc-cache -f "$HOME/.local/share/fonts"
    rm /tmp/JetBrainsMono.tar.xz
    ;;
  esac
  echo "JetBrainsMono Nerd Font installed"
}

echo "Installing Nerd Font..."
install_nerd_font

# ===========================================
# Done
# ===========================================

echo ""
echo "============================================"
echo " All tools installed!"
echo "============================================"
echo ""