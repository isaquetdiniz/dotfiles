#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dotfiles Setup Script
# Multiplataform, idempotent setup for macOS, Linux, and GCP workstations.
# Usage: ./setup.sh [--user]
#   --user: Install everything in ~/.local/bin (for ephemeral environments)
# ==============================================================================

DOTFILES_REPO="https://github.com/isaquetdiniz/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
USER_MODE=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --user) USER_MODE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Darwin) OS_TYPE="macos" ;;
  Linux)  OS_TYPE="linux" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_TYPE="amd64" ;;
  aarch64|arm64) ARCH_TYPE="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ==============================================================================
# Helper functions
# ==============================================================================

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

command_exists() { command -v "$1" &>/dev/null; }

ensure_local_bin() {
  mkdir -p "$HOME/.local/bin"
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

install_github_binary() {
  local name="$1" repo="$2" pattern="$3" strip_components="${4:-1}"

  if command_exists "$name"; then
    success "$name already installed"
    return
  fi

  info "Installing $name from GitHub..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local url
  url="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | grep "browser_download_url.*${pattern}" \
    | head -1 \
    | cut -d '"' -f 4)"

  if [[ -z "$url" ]]; then
    warn "Could not find release for $name (pattern: $pattern)"
    rm -rf "$tmp_dir"
    return 1
  fi

  if [[ "$url" == *.tar.gz || "$url" == *.tgz ]]; then
    curl -fsSL "$url" | tar xz -C "$tmp_dir" --strip-components="$strip_components"
  elif [[ "$url" == *.zip ]]; then
    curl -fsSL "$url" -o "$tmp_dir/archive.zip"
    unzip -q "$tmp_dir/archive.zip" -d "$tmp_dir"
  elif [[ "$url" == *.deb ]]; then
    curl -fsSL "$url" -o "$tmp_dir/package.deb"
    dpkg-deb -x "$tmp_dir/package.deb" "$tmp_dir"
    cp "$tmp_dir/usr/bin/$name" "$HOME/.local/bin/"
    rm -rf "$tmp_dir"
    success "$name installed"
    return
  fi

  # Find and copy the binary
  local bin_path
  bin_path="$(find "$tmp_dir" -name "$name" -type f -executable 2>/dev/null | head -1)"
  if [[ -z "$bin_path" ]]; then
    bin_path="$(find "$tmp_dir" -name "$name" -type f 2>/dev/null | head -1)"
  fi

  if [[ -n "$bin_path" ]]; then
    cp "$bin_path" "$HOME/.local/bin/$name"
    chmod +x "$HOME/.local/bin/$name"
    success "$name installed"
  else
    warn "Could not find $name binary in release archive"
  fi

  rm -rf "$tmp_dir"
}

brew_or_manual() {
  local name="$1"
  local brew_name="${2:-$1}"
  shift 2

  if command_exists "$name"; then
    success "$name already installed"
    return
  fi

  if [[ "$OS_TYPE" == "macos" && "$USER_MODE" == false ]]; then
    info "Installing $name via brew..."
    brew install "$brew_name"
  else
    "$@"
  fi
}

install_tool() {
  local name="$1"
  local brew_name="${2:-$1}"
  local apt_name="${3:-$1}"
  shift 3

  if command_exists "$name"; then
    success "$name already installed"
    return
  fi

  if [[ "$USER_MODE" == false ]]; then
    if [[ "$OS_TYPE" == "macos" ]]; then
      info "Installing $name via brew..."
      brew install "$brew_name"
      return
    elif [[ "$OS_TYPE" == "linux" ]]; then
      info "Installing $name via apt..."
      sudo apt-get install -y "$apt_name"
      return
    fi
  fi

  # Fallback: manual install function passed as remaining args
  "$@"
}

# ==============================================================================
# Tool installations
# ==============================================================================

install_zsh() {
  if command_exists zsh; then
    success "zsh already installed"
    return
  fi

  if [[ "$USER_MODE" == true ]]; then
    warn "zsh not found and --user mode cannot install it. Please install zsh manually."
    return
  fi

  if [[ "$OS_TYPE" == "macos" ]]; then
    brew install zsh
  else
    sudo apt-get install -y zsh
  fi
  success "zsh installed"
}

install_fzf() {
  if command_exists fzf; then
    success "fzf already installed"
    return
  fi

  if [[ "$USER_MODE" == false && "$OS_TYPE" == "macos" ]]; then
    brew install fzf
  elif [[ "$USER_MODE" == false && "$OS_TYPE" == "linux" ]]; then
    sudo apt-get install -y fzf
  else
    info "Installing fzf via git clone..."
    if [[ -d "$HOME/.fzf" ]]; then
      git -C "$HOME/.fzf" pull --quiet
    else
      git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    "$HOME/.fzf/install" --bin --no-bash --no-fish --no-update-rc
    cp "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/"
  fi
  success "fzf installed"
}

install_ripgrep() {
  install_tool "rg" "ripgrep" "ripgrep" \
    install_github_binary "rg" "BurntSushi/ripgrep" "ripgrep-.*-${ARCH}.*linux.*tar.gz"
}

install_bat() {
  if command_exists bat || command_exists batcat; then
    success "bat already installed"
    return
  fi

  if [[ "$USER_MODE" == false ]]; then
    if [[ "$OS_TYPE" == "macos" ]]; then
      brew install bat
      return
    elif [[ "$OS_TYPE" == "linux" ]]; then
      sudo apt-get install -y bat
      return
    fi
  fi

  install_github_binary "bat" "sharkdp/bat" "bat-.*-${ARCH}.*linux.*tar.gz"
}

install_starship() {
  if command_exists starship; then
    success "starship already installed"
    return
  fi

  if [[ "$USER_MODE" == false && "$OS_TYPE" == "macos" ]]; then
    brew install starship
  else
    info "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  fi
  success "starship installed"
}

install_eza() {
  brew_or_manual "eza" "eza" \
    install_github_binary "eza" "eza-community/eza" "eza_${ARCH}.*linux.*tar.gz" 0
}

install_zoxide() {
  if command_exists zoxide; then
    success "zoxide already installed"
    return
  fi

  if [[ "$USER_MODE" == false && "$OS_TYPE" == "macos" ]]; then
    brew install zoxide
  else
    info "Installing zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi
  success "zoxide installed"
}

install_dust() {
  brew_or_manual "dust" "dust" \
    install_github_binary "dust" "bootandy/dust" "dust-.*-${ARCH}.*linux.*tar.gz"
}

install_mise() {
  if command_exists mise; then
    success "mise already installed"
    return
  fi

  if [[ "$USER_MODE" == false && "$OS_TYPE" == "macos" ]]; then
    brew install mise
  else
    info "Installing mise..."
    curl -fsSL https://mise.jdx.dev/install.sh | sh
  fi
  success "mise installed"
}

install_lazygit() {
  brew_or_manual "lazygit" "lazygit" \
    install_github_binary "lazygit" "jesseduffield/lazygit" "lazygit_.*_linux_${ARCH}.tar.gz" 0
}

install_lazydocker() {
  if command_exists lazydocker; then
    success "lazydocker already installed"
    return
  fi

  if [[ "$USER_MODE" == false && "$OS_TYPE" == "macos" ]]; then
    brew install lazydocker
  else
    info "Installing lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  fi
  success "lazydocker installed"
}

install_zellij() {
  brew_or_manual "zellij" "zellij" \
    install_github_binary "zellij" "zellij-org/zellij" "zellij-${ARCH}.*linux.*tar.gz" 0
}

install_claude() {
  if command_exists claude; then
    success "claude already installed"
    return
  fi

  info "Installing claude..."
  curl -fsSL https://claude.ai/install.sh | bash
  success "claude installed"
}

install_nerd_font() {
  local font_name="JetBrainsMono"

  if [[ "$OS_TYPE" == "macos" ]]; then
    local font_dir="$HOME/Library/Fonts"
  else
    local font_dir="$HOME/.local/share/fonts"
  fi

  if ls "$font_dir"/${font_name}*.ttf &>/dev/null; then
    success "JetBrainsMono Nerd Font already installed"
    return
  fi

  info "Installing JetBrainsMono Nerd Font..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local url
  url="$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
    | grep "browser_download_url.*${font_name}.zip" \
    | head -1 \
    | cut -d '"' -f 4)"

  if [[ -z "$url" ]]; then
    warn "Could not find JetBrainsMono Nerd Font release"
    rm -rf "$tmp_dir"
    return 1
  fi

  curl -fsSL "$url" -o "$tmp_dir/font.zip"
  mkdir -p "$font_dir"
  unzip -qo "$tmp_dir/font.zip" -d "$font_dir" "*.ttf"
  rm -rf "$tmp_dir"

  if [[ "$OS_TYPE" == "linux" ]]; then
    fc-cache -f "$font_dir" 2>/dev/null || true
  fi

  success "JetBrainsMono Nerd Font installed"
}

# ==============================================================================
# ZSH Plugins
# ==============================================================================

install_zsh_plugins() {
  local plugins_dir="$HOME/.zsh"
  mkdir -p "$plugins_dir"

  local plugins=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "MichaelAquilina/zsh-you-should-use"
    "zsh-users/zsh-completions"
    "Aloxaf/fzf-tab"
  )

  for plugin in "${plugins[@]}"; do
    local name="${plugin##*/}"
    local dest="$plugins_dir/$name"

    if [[ -d "$dest" ]]; then
      info "Updating $name..."
      git -C "$dest" pull --quiet
    else
      info "Cloning $name..."
      git clone --depth 1 "https://github.com/$plugin.git" "$dest"
    fi
  done

  success "ZSH plugins installed"
}

# ==============================================================================
# Config symlinks
# ==============================================================================

create_symlinks() {
  info "Creating config symlinks..."

  # .zshrc
  ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

  # Git
  ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  ln -sf "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

  # Zellij
  mkdir -p "$HOME/.config/zellij"
  ln -sf "$DOTFILES_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

  # Claude Code
  mkdir -p "$HOME/.claude"
  ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

  # Claude settings.json (copy, don't symlink — only if not exists)
  if [[ ! -f "$HOME/.claude/settings.json" ]]; then
    cp "$DOTFILES_DIR/claude/settings.json.example" "$HOME/.claude/settings.json"
    warn "Created ~/.claude/settings.json from template. Edit <YOUR_PROJECT_ID> before using Claude."
  fi

  # .gitconfig-local (copy example only if not exists)
  if [[ ! -f "$HOME/.gitconfig-local" ]]; then
    cp "$DOTFILES_DIR/git/.gitconfig-local.example" "$HOME/.gitconfig-local"
    warn "Created ~/.gitconfig-local from template. Edit your name, email, and signingkey."
  fi

  success "Config symlinks created"
}

# ==============================================================================
# Default shell
# ==============================================================================

set_default_shell() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    success "ZSH is already the default shell"
    return
  fi

  local zsh_path
  zsh_path="$(which zsh)"

  if [[ "$USER_MODE" == true ]]; then
    warn "Cannot change default shell in --user mode. Start zsh manually or add 'exec zsh' to your .bashrc"
    return
  fi

  if command_exists chsh; then
    info "Setting ZSH as default shell..."
    chsh -s "$zsh_path"
    success "Default shell changed to ZSH"
  else
    warn "chsh not available. Set your shell manually to: $zsh_path"
  fi
}

# ==============================================================================
# Dotfiles repo
# ==============================================================================

clone_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    info "Updating dotfiles..."
    git -C "$DOTFILES_DIR" pull --quiet
  else
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  success "Dotfiles ready at $DOTFILES_DIR"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  echo ""
  echo "=========================================="
  echo " Dotfiles Setup"
  echo " OS: $OS_TYPE | Arch: $ARCH_TYPE | User mode: $USER_MODE"
  echo "=========================================="
  echo ""

  ensure_local_bin

  clone_dotfiles

  # Install tools
  install_zsh
  install_fzf
  install_ripgrep
  install_bat
  install_starship
  install_eza
  install_zoxide
  install_dust
  install_mise
  install_lazygit
  install_lazydocker
  install_zellij
  install_claude
  install_nerd_font

  # Plugins and configs
  install_zsh_plugins
  create_symlinks
  set_default_shell

  echo ""
  echo "=========================================="
  echo " Setup complete!"
  echo "=========================================="
  echo ""
  echo "Next steps:"
  if [[ ! -f "$HOME/.gitconfig-local" ]] || grep -q "Your Name" "$HOME/.gitconfig-local" 2>/dev/null; then
    echo "  1. Edit ~/.gitconfig-local with your name, email, and signingkey"
  fi
  if grep -q "YOUR_PROJECT_ID" "$HOME/.claude/settings.json" 2>/dev/null; then
    echo "  2. Edit ~/.claude/settings.json and replace <YOUR_PROJECT_ID>"
  fi
  echo "  - Restart your terminal or run: exec zsh"
  echo ""
}

main
