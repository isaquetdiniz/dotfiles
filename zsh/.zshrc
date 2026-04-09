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
