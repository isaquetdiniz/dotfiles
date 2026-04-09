# Setup Script — Design Spec

## Objetivo

Script multiplataforma e idempotente (`setup.sh`) para configurar o ambiente de desenvolvimento em qualquer máquina (macOS, Linux pessoal, workstation GCP).

## Modos de operação

- **Padrão** (sem flag): usa gerenciador de pacotes do sistema (`brew` no macOS, `apt` no Linux)
- **`--user`**: instala tudo em `~/.local/bin` (para ambientes efêmeros como workstation GCP)

## Detecção de SO

Usa `uname -s` para distinguir `darwin` (macOS) vs `linux`.

## Fluxo de execução

1. **Detectar SO e modo** — macOS/Linux, flag `--user`
2. **Criar `~/.local/bin`** se modo `--user`
3. **Clonar/atualizar dotfiles** — `https://github.com/isaquetdiniz/dotfiles` em `~/dotfiles` (clone se não existe, `git pull` se existe)
4. **Instalar ferramentas** — cada função verifica `command -v` antes de instalar
5. **Clonar/atualizar plugins ZSH** — 5 plugins em `~/.zsh/`
6. **Symlinks de configs** — `.zshrc`, `.gitconfig`, `.gitignore_global`
7. **Definir ZSH como shell padrão** — `chsh` se disponível
8. **Mensagem de pós-instalação** — instruções para criar `.gitconfig-local`

## Ferramentas e métodos de instalação

| Ferramenta | macOS (padrão) | Linux (padrão) | `--user` |
|---|---|---|---|
| zsh | `brew install` | `apt install` | já presente / skip |
| fzf | `brew install` | `apt install` | git clone `~/.fzf` + install |
| ripgrep | `brew install` | `apt install` | binário GitHub → `~/.local/bin` |
| bat | `brew install` | `apt install` | binário GitHub → `~/.local/bin` |
| starship | `brew install` | script oficial | script oficial (`BIN_DIR=~/.local/bin`) |
| eza | `brew install` | binário GitHub → `~/.local/bin` | binário GitHub → `~/.local/bin` |
| zoxide | `brew install` | script oficial | script oficial |
| dust | `brew install` | binário GitHub → `~/.local/bin` | binário GitHub → `~/.local/bin` |
| mise | `brew install` | script oficial | script oficial |
| lazygit | `brew install` | binário GitHub → `~/.local/bin` | binário GitHub → `~/.local/bin` |
| lazydocker | `brew install` | script oficial | script oficial |
| zellij | `brew install` | binário GitHub → `~/.local/bin` | binário GitHub → `~/.local/bin` |
| claude | npm global / script oficial | npm global / script oficial | npm global / script oficial |

## Plugins ZSH

Clonados em `~/.zsh/` (clone se não existe, `git pull` se existe):

- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-you-should-use
- zsh-completions
- fzf-tab

## Configs

### `.zshrc` unificado

Substitui `.zshrc-mac`. Usa condicionais por SO:

- `bat` vs `batcat` (Debian apt instala como `batcat`, binário manual como `bat`)
- PATH do Homebrew apenas no macOS
- Aliases `vi/vim→nvim` apenas se nvim estiver disponível

### `.gitconfig` unificado

Contém tudo que é compartilhado (aliases, core, merge, pull, init, gpg format).
Usa `[include]` para um `.gitconfig-local` com dados por máquina:

- `user.name`
- `user.email`
- `user.signingkey`

### Claude Code (`~/.claude/CLAUDE.md`)

Symlink do dotfiles. Contém preferências globais (workflow de orquestração, model assignment matrix). O `settings.json.example` é copiado (não linkado) para `~/.claude/settings.json` apenas se não existir — o usuário deve substituir `<YOUR_PROJECT_ID>` pelo project ID real.

### Zellij (`~/.config/zellij/config.kdl`)

Symlink do dotfiles. Config customizada com keybindings vim (hjkl), tema gruvbox-dark, pane_frames desabilitado.

### `.gitignore_global`

Symlink direto do dotfiles.

## Idempotência

- Cada função de instalação verifica `command -v <tool>` antes de agir
- Clone de repos verifica se diretório já existe, faz `git pull` se sim
- Symlinks usam `ln -sf` (force)
- Script pode rodar N vezes sem efeito colateral

## Exclusões

- Neovim, Alacritty, Ghostty, AutoHotkey, luarocks — irrelevantes para workstation remota
