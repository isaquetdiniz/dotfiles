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

### Font
- [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) — installed automatically from GitHub releases

### Terminal Emulators (manual setup)
- [Alacritty](https://alacritty.org/) — config + gruvbox themes
- [Ghostty](https://ghostty.org) — config

## Post-Setup

After running `setup.sh`, edit these files with your machine-specific settings:

1. `~/.gitconfig-local` — your name, email, and SSH signing key
2. `~/.claude/settings.json` — your Vertex AI project ID

Then restart your terminal or run `exec zsh`.
