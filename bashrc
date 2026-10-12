# shellcheck disable=SC2148
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# ~/.bashrc: bash-only options, prompt, completions.
# Shared aliases/functions: ~/.config/my-shell/common.sh

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# History
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:ll:cd:cd -:pwd:exit:clear:c:cls:history"
shopt -s histappend
shopt -s cmdhist
shopt -s lithist
shopt -s autocd
HISTSIZE=36000
HISTFILESIZE=36000
HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

shopt -s checkwinsize
shopt -s globstar extglob
# optional: set -o noclobber   # block > overwrite; use >| to force
export TIMEFORMAT='real %3R  user %3U  sys %3S'

# lesspipe (Debian/Ubuntu) or lesspipe.sh (RHEL/CentOS/Fedora)
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [ -x /usr/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh lesspipe.sh)"
fi

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    if [ "$EUID" -eq 0 ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
    fi
else
    if [ "$EUID" -eq 0 ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
    fi
fi

# Kubernetes prompt via kube-ps1 (context + namespace).
KUBE_PS1_HIDE_IF_NOCONTEXT="${KUBE_PS1_HIDE_IF_NOCONTEXT:-true}"

_bashrc_load_kube_ps1() {
    declare -F kube_ps1 >/dev/null 2>&1 && return 0
    command -v kubectl >/dev/null 2>&1 || return 1

    local candidate
    local bashrc_dir
    bashrc_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

    for candidate in \
        "${KUBE_PS1_SH:-}" \
        "${bashrc_dir:+$bashrc_dir/kube-ps1.sh}" \
        /usr/share/kube-ps1/kube-ps1.sh \
        /usr/local/share/kube-ps1/kube-ps1.sh \
        /usr/local/opt/kube-ps1/share/kube-ps1/kube-ps1.sh \
        /opt/homebrew/opt/kube-ps1/share/kube-ps1/kube-ps1.sh \
        "${HOME}/.local/share/kube-ps1/kube-ps1.sh"
    do
        [ -n "$candidate" ] && [ -r "$candidate" ] || continue
        # shellcheck disable=SC1090
        . "$candidate" >/dev/null 2>&1 || continue
        declare -F kube_ps1 >/dev/null 2>&1 && return 0
    done
    return 1
}

_bashrc_load_kube_ps1 || true

if command -v kubectl >/dev/null 2>&1 && ! declare -F kube_ps1 >/dev/null 2>&1; then
    (
        __kube_ps1_url="https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh"
        __kube_ps1_dest="${HOME}/.local/share/kube-ps1/kube-ps1.sh"
        __kube_ps1_lock="/tmp/bashrc.kube-ps1.lock"
        __kube_ps1_tmp="$(mktemp 2>/dev/null)" || exit 0

        trap 'rm -f "$__kube_ps1_tmp"; rmdir "$__kube_ps1_lock" 2>/dev/null' EXIT
        mkdir "$__kube_ps1_lock" 2>/dev/null || exit 0
        [ ! -e "$__kube_ps1_dest" ] || exit 0
        mkdir -p "$(dirname "$__kube_ps1_dest")" 2>/dev/null || exit 0

        if command -v curl >/dev/null 2>&1; then
            curl -fsSL --max-time 15 "$__kube_ps1_url" -o "$__kube_ps1_tmp" || exit 0
        elif command -v wget >/dev/null 2>&1; then
            wget -qT 15 -O "$__kube_ps1_tmp" "$__kube_ps1_url" || exit 0
        else
            exit 0
        fi
        [ -s "$__kube_ps1_tmp" ] || exit 0
        bash -n "$__kube_ps1_tmp" >/dev/null 2>&1 || exit 0
        mv "$__kube_ps1_tmp" "$__kube_ps1_dest" 2>/dev/null || exit 0
    ) >/dev/null 2>&1 &
    disown "$!" 2>/dev/null || true
fi

# Command elapsed time (DEBUG trap + PROMPT_COMMAND)
_cmd_start_time=
_cmd_timer_active=0
_cmd_just_ran=0

function _cmd_timer_start {
    [[ "$BASH_COMMAND" == "my_prompt"* ]] && return
    [[ "$BASH_COMMAND" == "_cmd_timer_start" ]] && return
    [[ "$BASH_COMMAND" == "_kube_ps1_prompt_update" ]] && return
    [[ "$BASH_COMMAND" == history* ]] && return
    [[ -z "${BASH_COMMAND// }" ]] && return

    if [ "$_cmd_timer_active" -eq 0 ]; then
        _cmd_start_time=$SECONDS
        _cmd_timer_active=1
        _cmd_just_ran=1
    fi
}
trap '_cmd_timer_start' DEBUG

function my_prompt {
    local retval=$?
    local field3='$([ \j -gt 0 ] && echo \ jobs:\j)'"$(echo \ rc:$retval)"

    if declare -F _kube_ps1_prompt_update >/dev/null 2>&1; then
        _kube_ps1_prompt_update >/dev/null 2>&1 || true
    fi

    local elapsed_str=""
    if [ "$_cmd_just_ran" -eq 1 ] && [ -n "$_cmd_start_time" ]; then
        local elapsed=$(( SECONDS - _cmd_start_time ))
        if [ "$elapsed" -ge 1 ]; then
            elapsed_str=" \[\033[01;33m\][⏱ ${elapsed}s]\[\033[00m\]"
        fi
    fi
    _cmd_start_time=
    _cmd_timer_active=0
    _cmd_just_ran=0

    local user_color
    if [ "$EUID" -eq 0 ]; then
        user_color="\[\033[01;31m\]"
    else
        user_color="\[\033[01;36m\]"
    fi

    if [ "$EUID" -eq 0 ]; then
        local prompt_char="\[\033[01;31m\]#\[\033[00m\]"
    else
        local prompt_char="\[\033[01;34m\]\$\[\033[00m\]"
    fi

    local git_str=""
    local branch
    branch=$(git -C . rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_str=" \[\033[01;32m\](${branch})\[\033[00m\]"
    fi

    local kube_str=""
    if declare -F kube_ps1 >/dev/null 2>&1 && command -v kubectl >/dev/null 2>&1; then
        local kube_out
        kube_out="$(kube_ps1 2>/dev/null)"
        if [ -n "$kube_out" ] && [[ "${KUBE_PS1_CONTEXT:-}" != BINARY-N/A* ]]; then
            kube_str=" ${kube_out}"
        fi
    fi

    local cyan="\[\033[01;36m\]"
    local reset="\[\033[00m\]"
    PS1="${cyan}┌──${reset}${cyan}[${user_color}\u\[\033[01;36m\]@\H${cyan}]${reset}-${cyan}[\w]${reset}-\[\033[01;35m\][\t]${reset}\[\033[00;00m\]${field3}${git_str}${kube_str}${elapsed_str}\n${cyan}└─${reset}${prompt_char} "

    history -a
    history -n
}

__bashrc_prompt_command="${PROMPT_COMMAND:-}"
__bashrc_prompt_command="${__bashrc_prompt_command//_kube_ps1_prompt_update;/}"
__bashrc_prompt_command="${__bashrc_prompt_command//;_kube_ps1_prompt_update/}"
__bashrc_prompt_command="${__bashrc_prompt_command/#_kube_ps1_prompt_update/}"
__bashrc_prompt_command="${__bashrc_prompt_command/%_kube_ps1_prompt_update/}"
__bashrc_prompt_command="${__bashrc_prompt_command//my_prompt; /}"
__bashrc_prompt_command="${__bashrc_prompt_command//; my_prompt/}"
__bashrc_prompt_command="${__bashrc_prompt_command/#my_prompt/}"
__bashrc_prompt_command="${__bashrc_prompt_command/%my_prompt/}"
__bashrc_prompt_command="${__bashrc_prompt_command#; }"
__bashrc_prompt_command="${__bashrc_prompt_command%; }"
[[ "$__bashrc_prompt_command" == ":" ]] && __bashrc_prompt_command=
PROMPT_COMMAND="my_prompt${__bashrc_prompt_command:+; $__bashrc_prompt_command}"
unset __bashrc_prompt_command

unset color_prompt force_color_prompt

case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# bash-completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ -f /etc/profile.d/bash_completion.sh ]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/bash_completion.sh
fi

# Readline completion UX
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind 'set menu-complete-display-prefix on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set mark-directories on'
bind 'set mark-symlinked-directories on'
bind 'set visible-stats on'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

complete -o filenames -o nospace -A directory cd pushd

# Shared aliases + portable functions
if [ -f "${HOME}/.config/my-shell/common.sh" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.config/my-shell/common.sh"
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/shell/common.sh" ]; then
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/shell/common.sh"
fi

# Bash-only completions for short aliases
if [ -r /usr/share/bash-completion/completions/systemctl ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/completions/systemctl >/dev/null 2>&1 || true
fi
if declare -F _systemctl >/dev/null 2>&1; then
    complete -F _systemctl sc
fi

if [ -r /usr/share/bash-completion/completions/docker ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/completions/docker >/dev/null 2>&1 || true
fi
if declare -F _docker >/dev/null 2>&1; then
    complete -F _docker d
fi

DC_AUTOBASH_COMPLETE_FILE="/etc/bash_completion.d/docker-compose"
if [ -r "$DC_AUTOBASH_COMPLETE_FILE" ]; then
    # shellcheck disable=SC1090
    . "$DC_AUTOBASH_COMPLETE_FILE" >/dev/null 2>&1 || true
    if declare -F _docker_compose >/dev/null 2>&1; then
        complete -F _docker_compose dc
    fi
elif [ ! -e "$DC_AUTOBASH_COMPLETE_FILE" ]; then
    (
        __dc_url="https://raw.githubusercontent.com/docker/compose/1.23.2/contrib/completion/bash/docker-compose"
        __dc_dest="/etc/bash_completion.d/docker-compose"
        __dc_lock="/tmp/bashrc.docker-compose.completion.lock"
        __dc_tmp="$(mktemp 2>/dev/null)" || exit 0

        trap 'rm -f "$__dc_tmp"; rmdir "$__dc_lock" 2>/dev/null' EXIT
        mkdir "$__dc_lock" 2>/dev/null || exit 0
        [ ! -e "$__dc_dest" ] || exit 0

        if command -v curl >/dev/null 2>&1; then
            curl -fsSL --max-time 15 "$__dc_url" -o "$__dc_tmp" || exit 0
        elif command -v wget >/dev/null 2>&1; then
            wget -qT 15 -O "$__dc_tmp" "$__dc_url" || exit 0
        else
            exit 0
        fi
        [ -s "$__dc_tmp" ] || exit 0

        if [ -w "$(dirname "$__dc_dest")" ]; then
            cp "$__dc_tmp" "$__dc_dest" 2>/dev/null || exit 0
        elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
            sudo -n cp "$__dc_tmp" "$__dc_dest" 2>/dev/null || exit 0
        else
            exit 0
        fi
    ) >/dev/null 2>&1 &
    disown "$!" 2>/dev/null || true
fi
unset DC_AUTOBASH_COMPLETE_FILE

if command -v kubectl >/dev/null 2>&1; then
    if ! declare -F __start_kubectl >/dev/null 2>&1; then
        # shellcheck disable=SC1090
        source <(kubectl completion bash 2>/dev/null) || true
    fi
    if declare -F __start_kubectl >/dev/null 2>&1; then
        complete -o default -F __start_kubectl k
    fi
fi

# User overrides — sourced last so custom aliases/functions win
if [ -f ~/.bash_aliases ]; then
    # shellcheck disable=SC1090
    . ~/.bash_aliases
fi
