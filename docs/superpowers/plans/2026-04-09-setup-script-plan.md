# Setup Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a multiplataform, idempotent setup script that configures the dev environment on macOS, Linux, and GCP workstations.

**Architecture:** Single `setup.sh` with OS detection and `--user` flag. Unified config files (`.zshrc`, `.gitconfig`) with OS conditionals and `[include]` for machine-specific data. All tool installs wrapped in idempotent functions that check `command -v` before acting.

**Tech Stack:** Bash, git, symlinks, GitHub releases API for binary downloads.

---

### Task 1: Create unified `.zshrc`

**Files:**
- Create: `zsh/.zshrc`
- Delete: `zsh/.zshrc-mac` (after creating unified version)

- [ ] **Step 1: Create `zsh/.zshrc` with OS conditionals**

```bash
# ==============================================================================
# 1. VARIÁVEIS DE AMBIENTE E PATH
# ==============================================================================
export PATH="$HOME/.local/bin:$PATH"

if [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
fi

# ==============================================================================
# 2. CONFIGURAÇÕES DO ZSH E HISTÓRICO (Essencial)
# ==============================================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS       # Não salva comandos duplicados em sequência
setopt HIST_IGNORE_SPACE      # Não salva comandos que começam com espaço (útil para senhas)
setopt INC_APPEND_HISTORY     # Salva o comando imediatamente após a execução, não ao fechar o terminal
setopt SHARE_HISTORY          # Compartilha o histórico entre abas abertas simultaneamente

# ==============================================================================
# 3. AUTOCOMPLETAR (Completions)
# ==============================================================================

# Adiciona os completions customizados
fpath=(~/.zsh/zsh-completions/src $fpath)

# Inicializa o sistema de autocompletar com cache para carregar mais rápido
autoload -Uz compinit && compinit -C

# ==============================================================================
# 4. INICIALIZAÇÃO DE FERRAMENTAS E AMBIENTES
# ==============================================================================

eval "$(mise activate zsh)"

# Zoxide (Substituindo o CD nativamente)
eval "$(zoxide init zsh --cmd cd)"

# Inicialização do FZF para o histórico (CTRL+R) e arquivos (CTRL+T)
eval "$(fzf --zsh)"
# Opcional: Fazer o FZF usar o bat para visualizar o conteúdo dos arquivos durante a busca
if command -v bat &>/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
elif command -v batcat &>/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'batcat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
fi

eval "$(starship init zsh)"

# ==============================================================================
# 5. ALIASES
# ==============================================================================

alias ls="eza --icons"
alias ll="eza --icons -lh"        # Dica: Lista com detalhes
alias la="eza --icons -lah"       # Dica: Lista com detalhes e arquivos ocultos
alias lg="lazygit"
alias ld="lazydocker"
alias rg="rg --hidden --glob '!.git'" # Usa o ripgrep ignorando a pasta .git

# bat vs batcat (Debian apt instala como batcat, binário manual e macOS como bat)
if command -v bat &>/dev/null; then
  alias cat="bat --theme gruvbox-dark"
elif command -v batcat &>/dev/null; then
  alias cat="batcat --theme gruvbox-dark"
fi

# Neovim aliases (apenas se disponível)
if command -v nvim &>/dev/null; then
  alias vi="nvim"
  alias vim="nvim"
fi

# ==============================================================================
# 6. PLUGINS E TEMAS
# ==============================================================================
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh
# Previews interativos para o fzf-tab
# Usa o eza para mostrar o conteúdo de pastas ao usar o comando cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# Usa o bat para mostrar o conteúdo de arquivos ao usar comandos como cat, nvim, etc.
if command -v bat &>/dev/null; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers,changes $realpath'
elif command -v batcat &>/dev/null; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'batcat --color=always --style=numbers,changes $realpath'
fi

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-you-should-use/you-should-use.plugin.zsh

# ATENÇÃO: zsh-syntax-highlighting DEVE ser a última linha do arquivo
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

- [ ] **Step 2: Delete `zsh/.zshrc-mac`**

```bash
git rm zsh/.zshrc-mac
```

- [ ] **Step 3: Commit**

```bash
git add zsh/.zshrc
git commit -m "feat: create unified .zshrc with OS conditionals

Replaces .zshrc-mac with a single .zshrc that handles macOS and Linux
differences via runtime detection (bat vs batcat, nvim availability,
macOS-specific PATH entries)."
```

---

### Task 2: Create unified `.gitconfig`

**Files:**
- Create: `git/.gitconfig`
- Create: `git/.gitconfig-local.example`
- Delete: `git/.gitconfig-macos`

- [ ] **Step 1: Create `git/.gitconfig` with shared settings and include**

```ini
[include]
    path = ~/.gitconfig-local
[init]
    defaultBranch = main
[core]
    editor = code --wait
    excludesfile = ~/.gitignore_global
[github]
    user = isaquetdiniz
[commit]
    gpgsign = true
[gpg]
    format = ssh
[pull]
    rebase = true
[merge]
    conflictstyle = zdiff3
[alias]
    s = status -s
    a = add .
    c = !git add . && git commit -m
    amend = !git add . && git commit --amend --no-edit
    l = !git log --pretty=format:'%C(blue)%h%C(red)%d %C(white)%s %C(cyan)[%cn] %C(green)%cr'
    lg = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    undo = reset HEAD~1
```

- [ ] **Step 2: Create `git/.gitconfig-local.example`**

```ini
[user]
    name = Your Name
    email = your@email.com
    signingkey = /path/to/.ssh/your-signing-key.pub
```

- [ ] **Step 3: Delete `git/.gitconfig-macos`**

```bash
git rm git/.gitconfig-macos
```

- [ ] **Step 4: Commit**

```bash
git add git/.gitconfig git/.gitconfig-local.example
git commit -m "feat: create unified .gitconfig with [include] for local settings

Shared aliases, core, merge, pull settings in .gitconfig.
Machine-specific user data (name, email, signingkey) goes in
~/.gitconfig-local (not tracked). Example file provided."
```

---

### Task 3: Create `setup.sh` — core structure and OS detection

**Files:**
- Create: `setup.sh`

- [ ] **Step 1: Create `setup.sh` with header, flags, OS detection, and helper functions**

```bash
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

apt_or_manual() {
  local name="$1"
  local apt_name="${2:-$1}"
  shift 2

  if command_exists "$name"; then
    success "$name already installed"
    return
  fi

  if [[ "$OS_TYPE" == "linux" && "$USER_MODE" == false ]]; then
    info "Installing $name via apt..."
    sudo apt-get install -y "$apt_name"
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
```

- [ ] **Step 2: Make executable**

```bash
chmod +x setup.sh
```

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): add core structure with OS detection and helpers

Includes --user flag, OS/arch detection, and helper functions for
idempotent installation from brew, apt, or GitHub releases."
```

---

### Task 4: Add tool installation functions to `setup.sh`

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Add individual tool install functions after the helpers section**

```bash
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
  # On Debian apt, binary is 'batcat'. On macOS/manual install, it's 'bat'.
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
    install_github_binary "lazygit" "jesseduffield/lazygit" "lazygit_.*_Linux_${ARCH}.tar.gz" 0
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
  if command_exists npm; then
    npm install -g @anthropic-ai/claude-code
  else
    warn "npm not found. Install Node.js first (e.g. via mise), then run: npm install -g @anthropic-ai/claude-code"
  fi
}
```

- [ ] **Step 2: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): add tool installation functions

Individual idempotent install functions for all tools:
zsh, fzf, ripgrep, bat, starship, eza, zoxide, dust,
mise, lazygit, lazydocker, zellij, claude."
```

---

### Task 5: Add plugin installation, symlinks, and main function to `setup.sh`

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Add ZSH plugin installation function**

```bash
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
```

- [ ] **Step 2: Add symlink and config functions**

```bash
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
```

- [ ] **Step 3: Add set_default_shell function**

```bash
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
```

- [ ] **Step 4: Add clone_dotfiles and main function**

```bash
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

  if [[ "$USER_MODE" == true ]]; then
    ensure_local_bin
  fi

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
```

- [ ] **Step 5: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): add plugins, symlinks, and main entrypoint

Completes setup.sh with ZSH plugin management, config symlinks,
default shell setup, dotfiles clone/update, and main orchestration."
```

---

### Task 6: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite README.md to reflect new structure**

```markdown
# Dotfiles

Personal dotfiles and development environment setup.

## Quick Start

```bash
# Clone and run (standard — uses brew/apt)
git clone https://github.com/isaquetdiniz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh

# For ephemeral environments like GCP Workstations (installs in ~/.local/bin)
./setup.sh --user
```

## What's Included

### Shell
- [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) — unified `.zshrc` with OS conditionals
- [starship](https://starship.rs/) — cross-shell prompt
- Plugins (installed in `~/.zsh/`):
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
  - [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
  - [zsh-completions](https://github.com/zsh-users/zsh-completions)
  - [fzf-tab](https://github.com/Aloxaf/fzf-tab)

### CLI Tools
- [eza](https://github.com/eza-community/eza) — modern `ls`
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd`
- [bat](https://github.com/sharkdp/bat) — better `cat`
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [ripgrep](https://github.com/BurntSushi/ripgrep) — fast `grep`
- [dust](https://github.com/bootandy/dust) — better `du`
- [mise](https://github.com/jdx/mise) — version manager
- [lazygit](https://github.com/jesseduffield/lazygit) — git TUI
- [lazydocker](https://github.com/jesseduffield/lazydocker) — docker TUI
- [zellij](https://github.com/zellij-org/zellij) — terminal multiplexer

### Git
- Unified `.gitconfig` with aliases, merge settings, GPG signing
- Machine-specific settings via `~/.gitconfig-local` (name, email, signingkey)
- Global `.gitignore`

### Claude Code
- Global `CLAUDE.md` with orchestration workflow and model assignment
- `settings.json.example` template (copied on first setup)

### Terminal Emulators (manual setup)
- [Alacritty](https://alacritty.org/) — config + gruvbox themes
- [Ghostty](https://ghostty.org) — config

## Post-Setup

After running `setup.sh`, edit these files with your machine-specific settings:

1. `~/.gitconfig-local` — your name, email, and SSH signing key
2. `~/.claude/settings.json` — your Vertex AI project ID

Then restart your terminal or run `exec zsh`.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for new setup script

Adds quick start, tool list, and post-setup instructions.
Reflects unified configs and --user flag for ephemeral environments."
```

---

### Task 7: Verify setup script

**Files:** None (verification only)

- [ ] **Step 1: Run shellcheck on setup.sh**

```bash
shellcheck setup.sh
```

Fix any issues found.

- [ ] **Step 2: Test dry run on current machine**

```bash
bash setup.sh --user
```

Verify:
- All tools that are already installed show "[OK] already installed"
- Symlinks are created correctly
- No errors in output

- [ ] **Step 3: Commit any fixes**

```bash
git add setup.sh
git commit -m "fix(setup): address shellcheck and runtime issues"
```
