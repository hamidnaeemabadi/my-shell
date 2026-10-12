#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# ~/.zshrc — Oh My Zsh plugins + builtins (no reinventing).
# Shared aliases/functions: ~/.config/my-shell/common.sh

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Don't inherit a stale kube-ps1 RPROMPT from a parent shell (e.g. nested `zsh`)
unset RPROMPT

# Theme — custom my-shell (matches bashrc my_prompt colors/structure)
# Installed to $ZSH_CUSTOM/themes/my-shell.zsh-theme by install.sh
ZSH_THEME="my-shell"
#ZSH_THEME="xiong-chiamiov-plus"
#ZSH_THEME="robbyrussell"
#ZSH_THEME="ys"

HIST_STAMPS="yyyy-mm-dd"

# ---------------------------------------------------------------------------
# Plugin config (must be set BEFORE sourcing oh-my-zsh.sh)
# ---------------------------------------------------------------------------

# ssh-agent → replaces bash `shad` (auto-start agent + add keys)
zstyle :omz:plugins:ssh-agent identities id_rsa
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lazy no

# kube-ps1 (only loaded when kubectl exists — avoids "(⎈|BINARY-N/A:N/A)")
KUBE_PS1_HIDE_IF_NOCONTEXT="${KUBE_PS1_HIDE_IF_NOCONTEXT:-true}"

# Core Oh My Zsh plugins (bundled). Third-party bundles → Antigen (below).
plugins=(
    aliases
    ansible
    brew
    debian
    dnf
    docker
    docker-compose
    gh
    git
    iterm2
    k9s
    kubectx
    kompose
    minikube
    mosh
    nmap
    pm2
    postgres
    qrcode
    rclone
    redis-cli
    ssh-agent
    sudo
    systemadmin
    systemd
    terraform
    tldr
    tmux
    ufw
    ubuntu
    z
    history
)

# Optional plugins — only if the tool/OS is present *and* works (silences OMZ noise)
# macos: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos
[[ "$(uname -s)" == Darwin ]] && plugins+=(macos)
command -v kubectl >/dev/null 2>&1 && plugins+=(kubectl kube-ps1)
command -v fzf >/dev/null 2>&1 && plugins+=(fzf)
# thefuck is broken on Python 3.12+ (removed stdlib `imp`). Skip unless it actually runs.
# Also drop any stale OMZ cache from a previous failed load.
if command -v thefuck >/dev/null 2>&1 && thefuck --alias >/dev/null 2>&1; then
    plugins+=(thefuck)
else
    rm -f "${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/thefuck" \
          "${HOME}/.oh-my-zsh/cache/thefuck" 2>/dev/null
fi

if [ -r "$ZSH/oh-my-zsh.sh" ]; then
    # shellcheck disable=SC1091
    source "$ZSH/oh-my-zsh.sh"
else
    echo "my-shell: Oh My Zsh not found at $ZSH — run install.sh or install OMZ first" >&2
fi

# kube-ps1 on RPROMPT when plugin loaded. Toggle: kubeon / kubeoff
if typeset -f kube_ps1 >/dev/null 2>&1; then
    RPROMPT='$(kube_ps1)'
fi

# ---------------------------------------------------------------------------
# Antigen — plugin manager (git.io/antigen → ~/.antigen.zsh)
# https://github.com/zsh-users/antigen
# Manage at runtime: antigen list | update | cleanup | selfupdate | reset
# ---------------------------------------------------------------------------
ANTIGEN="${ANTIGEN:-$HOME/.antigen.zsh}"
if [ -r "$ANTIGEN" ]; then
    # shellcheck disable=SC1090
    source "$ANTIGEN"

    # Ready-to-run third-party bundles (uncomment / add more as needed)
    antigen bundle zsh-users/zsh-autosuggestions
    antigen bundle zsh-users/zsh-syntax-highlighting
    # antigen bundle zsh-users/zsh-completions
    # antigen bundle zsh-users/zsh-history-substring-search
    # antigen bundle djui/alias-tips
    # antigen bundle hlissner/zsh-autopair
    # antigen bundle Aloxaf/fzf-tab

    antigen apply
else
    echo "my-shell: antigen not found at $ANTIGEN — re-run install.sh (MY_SHELL_TARGET=zsh)" >&2
fi

# ---------------------------------------------------------------------------
# Builtin zsh options (map bash shopt / HISTCONTROL / TIMEFORMAT)
# ---------------------------------------------------------------------------
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt MAGIC_EQUAL_SUBST
setopt NONOMATCH
setopt NOTIFY
setopt NUMERIC_GLOB_SORT
setopt PROMPT_SUBST
setopt EXTENDED_GLOB
setopt GLOB_STAR_SHORT 2>/dev/null || true

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=36000
SAVEHIST=36000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

REPORTTIME=3
TIMEFMT=$'real %*E  user %*U  sys %*S'

WORDCHARS=${WORDCHARS//\/}
PROMPT_EOL_MARK=""

# Keybindings
bindkey -e
bindkey ' ' magic-space
bindkey '^U' backward-kill-line
bindkey '^[[3;5~' kill-word
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[5~' beginning-of-buffer-or-history
bindkey '^[[6~' end-of-buffer-or-history
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[Z' undo
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true

alias history="history 0"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Distro fallbacks if OMZ custom plugins were not cloned
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    # shellcheck disable=SC1091
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    # shellcheck disable=SC1091
    . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [ -f /etc/zsh_command_not_found ]; then
    # shellcheck disable=SC1091
    . /etc/zsh_command_not_found
fi

# Shared aliases + portable functions (after plugins so our short names win on overlap)
if [ -f "${HOME}/.config/my-shell/common.sh" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.config/my-shell/common.sh"
fi

if [ -f ~/.zsh_aliases ]; then
    # shellcheck disable=SC1090
    . ~/.zsh_aliases
fi
