# shellcheck disable=SC2148
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
HISTIGNORE="ls:ll:cd:cd -:pwd:exit:clear:c:cls:history"

# append to the history file, don't overwrite it
shopt -s histappend
# multi-line commands as one history entry; keep newlines
shopt -s cmdhist
shopt -s lithist

# auto cd to the directory
shopt -s autocd

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=36000
HISTFILESIZE=36000
HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files
# lesspipe (Debian/Ubuntu) or lesspipe.sh (RHEL/CentOS/Fedora)
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [ -x /usr/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh lesspipe.sh)"
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
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
# https://github.com/jonmosco/kube-ps1
# Loaded only when kubectl exists; hidden when no current-context.
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

# Async install of kube-ps1 when kubectl exists but the script is not available yet.
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

# Track command start time for elapsed time display
_cmd_start_time=
_cmd_timer_active=0
_cmd_just_ran=0

function _cmd_timer_start {
    # Skip PROMPT_COMMAND internals and empty Enter presses.
    # BASH_COMMAND holds the actual command string being executed;
    # if it matches my_prompt (our PROMPT_COMMAND function) we ignore it.
    [[ "$BASH_COMMAND" == "my_prompt"* ]] && return
    [[ "$BASH_COMMAND" == "_cmd_timer_start" ]] && return
    [[ "$BASH_COMMAND" == "_kube_ps1_prompt_update" ]] && return
    [[ "$BASH_COMMAND" == history* ]] && return
    # Skip empty or whitespace-only commands
    [[ -z "${BASH_COMMAND// }" ]] && return

    if [ "$_cmd_timer_active" -eq 0 ]; then
        _cmd_start_time=$SECONDS
        _cmd_timer_active=1
        _cmd_just_ran=1
    fi
}
trap '_cmd_timer_start' DEBUG

function my_prompt {
    # Must run first in PROMPT_COMMAND so $? is the user's last command.
    local retval=$?
    local field3='$([ \j -gt 0 ] && echo \ jobs:\j)'"$(echo \ rc:$retval)"

    # Refresh kube-ps1 cache after status capture (keeps $? intact).
    if declare -F _kube_ps1_prompt_update >/dev/null 2>&1; then
        _kube_ps1_prompt_update >/dev/null 2>&1 || true
    fi

    # Elapsed time — only shown when the user actually ran a command
    local elapsed_str=""
    if [ "$_cmd_just_ran" -eq 1 ] && [ -n "$_cmd_start_time" ]; then
        local elapsed=$(( SECONDS - _cmd_start_time ))
        if [ "$elapsed" -ge 1 ]; then
            elapsed_str=" \[\033[01;33m\][⏱ ${elapsed}s]\[\033[00m\]"
        fi
    fi
    # Reset for next command
    _cmd_start_time=
    _cmd_timer_active=0
    _cmd_just_ran=0

    # Use red for root username only, cyan for everything else
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

    # Git branch detection
    local git_str=""
    local branch
    branch=$(git -C . rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_str=" \[\033[01;32m\](${branch})\[\033[00m\]"
    fi

    # Kubernetes context/namespace (kube-ps1) — only when kubectl exists and context is set
    local kube_str=""
    if declare -F kube_ps1 >/dev/null 2>&1 && command -v kubectl >/dev/null 2>&1; then
        local kube_out
        kube_out="$(kube_ps1 2>/dev/null)"
        if [ -n "$kube_out" ] && [[ "${KUBE_PS1_CONTEXT:-}" != BINARY-N/A* ]]; then
            kube_str=" ${kube_out}"
        fi
    fi

    # Line 1: ┌──(user@host)-[path]-[time] rc jobs git kube elapsed
    # Line 2: └─$
    local cyan="\[\033[01;36m\]"
    local reset="\[\033[00m\]"
    PS1="${cyan}┌──${reset}${cyan}[${user_color}\u\[\033[01;36m\]@\H${cyan}]${reset}-${cyan}[\w]${reset}-\[\033[01;35m\][\t]${reset}\[\033[00;00m\]${field3}${git_str}${kube_str}${elapsed_str}\n${cyan}└─${reset}${prompt_char} "

    # Share history across interactive terminals (after status capture).
    history -a
    history -n
}

# Keep PROMPT_COMMAND idempotent because this file can be sourced more than once.
# Also remove kube-ps1's own hook so my_prompt stays first (preserves $?).
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
# Drop leftover no-op from kube-ps1's default PROMPT_COMMAND=...:
[[ "$__bashrc_prompt_command" == ":" ]] && __bashrc_prompt_command=
PROMPT_COMMAND="my_prompt${__bashrc_prompt_command:+; $__bashrc_prompt_command}"
unset __bashrc_prompt_command

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
    *)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions — load ~/.bash_aliases at the END of this file (see bottom)
# so a broken aliases file cannot interrupt parsing of the main config.

# enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Bash autocompletion (profile.d — present on most distros)
if [ -f /etc/profile.d/bash_completion.sh ]; then
    source /etc/profile.d/bash_completion.sh
fi

# My Editor
export VISUAL=vim
export EDITOR=vim

# Modern Bash completion UX (readline)
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

# Directory-only completion for path navigation commands.
complete -o filenames -o nospace -A directory cd pushd

alias ll="ls -larthXS --group-directories-first --time-style='+%Y-%m-%d %H:%M:%S' --color=auto"
alias l="ls -larthXS --group-directories-first --time-style='+%Y-%m-%d %H:%M:%S' --color=auto"
alias lper="stat -c '%a %n' *"
alias la='ls -A'
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias cdd='cd ~/Downloads'
alias cde='cd /etc'
# Function to run ls after cd
function cd {
    builtin cd "$@" && ls -larth --group-directories-first
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

alias where=which
alias c='clear'
alias cls='clear'
alias hosts='sudo "$EDITOR" /etc/hosts'
alias lip="ip -o addr show | awk '{print \$2, \$4}'"
alias myip='curl -s http://ip-api.com/line/"$(curl -s icanhazip.com)"'

# Package manager aliases — Debian/Ubuntu
alias apt='sudo apt'
alias nala='sudo nala'
# Package manager aliases — RHEL/CentOS/Fedora
alias dnf='sudo dnf'
alias yum='sudo yum'
alias qproxy='sudo qproxy'
# Universal update function — detects the package manager
function update {
    read -rp "Update packages? [y/N] " _answer
    [[ "$_answer" != [yY] ]] && echo "Aborted." && return 0

    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt upgrade -y
    elif command -v dnf &>/dev/null; then
        sudo dnf upgrade -y
    elif command -v yum &>/dev/null; then
        sudo yum update -y
    else
        echo "No supported package manager found (apt/dnf/yum)"
    fi
}
alias less='less -NR'
alias v="vim"
alias tf="tail -f"
# DNS flush — works on both systemd-resolved (Ubuntu/RHEL 8+) and older RHEL (nscd/named)
function fdns {
    if command -v resolvectl &>/dev/null; then
        sudo resolvectl flush-caches && sudo resolvectl statistics
    elif command -v systemd-resolve &>/dev/null; then
        sudo systemd-resolve --flush-caches && sudo systemd-resolve --statistics
    elif command -v nscd &>/dev/null; then
        sudo nscd -i hosts
    else
        echo "No supported DNS cache manager found"
    fi
}

dns-test() {
    local domain="${1:-}"
    local entry
    local name
    local ip
    local result
    local resolved
    local query_timeout=5
    local dns_servers=(
        "tci|5.200.200.200"
        "recursive1.dci.ir|217.218.127.127"
        "recursive2.dci.ir|217.218.155.155"
        "pns01.afranet.ir|79.175.137.4"
        "pns02.afranet.ir|79.175.136.4"
        "dns1.begzar.ir|185.55.224.24"
        "dns2.begzar.ir|185.55.226.26"
        "dns3.begzar.ir|185.55.225.25"
        "dns.electro1|78.157.42.100"
        "dns.electro2|78.157.42.101"
        "DNS|178.252.149.220"
        "recursive1.dnspro.ir|87.107.110.109"
        "recursive2.dnspro.ir|87.107.110.110"
        "free.shecan.ir|178.22.122.100"
        "dns.shecan.ir|185.51.200.2"
        "403.online1|10.202.10.202"
        "403.online2|10.202.10.102"
        "403.online3|10.202.10.10"
        "403.online4|10.202.10.11"
        "dns94-1|94.103.125.157"
        "dns94-2|94.103.125.158"
        "beshkan1|181.41.194.177"
        "beshkan2|181.41.194.186"
        "dns5-1|5.202.100.100"
        "dns5-2|5.202.100.101"
        "level3-1|209.244.0.3"
        "level3-2|209.244.0.4"
        "dns85-1|85.15.1.14"
        "dns85-2|85.15.1.15"
    )

    if ! command -v nslookup >/dev/null 2>&1; then
        echo "Error: nslookup is required but not installed."
        return 1
    fi

    if [ -z "$domain" ]; then
        read -r -p "Enter domain to test: " domain
    fi

    if [ -z "$domain" ]; then
        echo "Error: domain is required."
        echo "Usage: dns-test <domain>"
        return 1
    fi

    echo "Testing DNS resolution for: $domain"
    echo "------------------------------------"

    for entry in "${dns_servers[@]}"; do
        name="${entry%%|*}"
        ip="${entry##*|}"
        result="$(timeout "${query_timeout}" nslookup "$domain" "$ip" 2>/dev/null)"

        if [ $? -eq 124 ]; then
            echo "⏱️  $name ($ip) -> TIMEOUT after ${query_timeout}s"
        elif echo "$result" | grep -q "Address:"; then
            resolved="$(echo "$result" | grep "Address:" | tail -n1 | awk '{print $2}')"
            echo "✅ $name ($ip) -> $resolved"
        else
            echo "❌ $name ($ip) -> FAILED"
        fi

        sleep 2
    done
}

unalias random-password 2>/dev/null || true
random-password() {
    local length="${1:-}"

    if [ -z "$length" ]; then
        read -r -p "Enter password length [48]: " length
        length="${length:-48}"
    fi

    head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c "${length}"
    echo
}

top-ram-10() {
    ps aux --sort=-%mem | head -11
}

top-cpu-10() {
    ps aux --sort=-%cpu | head -11
}

top-ram-10-10min() {
    if command -v journalctl >/dev/null 2>&1; then
        local output
        output="$(journalctl --since "10 minutes ago" --no-pager | grep -Ei 'out of memory|oom|killed process|memory cgroup|invoked oom-killer|memory' | tail -100)"
        if [ -n "$output" ]; then
            echo "$output"
        else
            ps -eo pid,user,etimes,%mem,%cpu,comm --sort=-%mem | awk 'NR==1 || $3 <= 600' | head -11
            echo
            echo "No RAM/OOM related journal entries found in the last 10 minutes."
            echo "For the previous boot, run: last-boot-ram-issues"
        fi
    else
        echo "journalctl is not available; historical RAM usage needs logging before reboot."
        return 1
    fi
}

top-cpu-10-10min() {
    if command -v journalctl >/dev/null 2>&1; then
        local output
        output="$(journalctl --since "10 minutes ago" --no-pager | grep -Ei 'cpu|load average|soft lockup|hard lockup|hung task|watchdog' | tail -100)"
        if [ -n "$output" ]; then
            echo "$output"
        else
            ps -eo pid,user,etimes,%mem,%cpu,comm --sort=-%cpu | awk 'NR==1 || $3 <= 600' | head -11
            echo
            echo "No CPU/load related journal entries found in the last 10 minutes."
            echo "For the previous boot, run: last-boot-cpu-issues"
        fi
    else
        echo "journalctl is not available; historical CPU usage needs logging before reboot."
        return 1
    fi
}

last-boot-ram-issues() {
    if command -v journalctl >/dev/null 2>&1; then
        local output
        output="$(journalctl -b -1 --no-pager | grep -Ei 'out of memory|oom|killed process|memory cgroup|invoked oom-killer' | tail -100)"
        if [ -n "$output" ]; then
            echo "$output"
        else
            echo "No RAM/OOM related journal entries found for the previous boot."
            echo "Check available boots with: journalctl --list-boots"
        fi
    else
        echo "journalctl is not available; check /var/log/syslog* or /var/log/kern.log* manually."
        return 1
    fi
}

last-boot-cpu-issues() {
    if command -v journalctl >/dev/null 2>&1; then
        local output
        output="$(journalctl -b -1 --no-pager | grep -Ei 'cpu|load average|soft lockup|hard lockup|hung task|watchdog' | tail -100)"
        if [ -n "$output" ]; then
            echo "$output"
        else
            echo "No CPU/load related journal entries found for the previous boot."
            echo "Check available boots with: journalctl --list-boots"
        fi
    else
        echo "journalctl is not available; check /var/log/syslog* or /var/log/kern.log* manually."
        return 1
    fi
}

last-boot-crash-issues() {
    if command -v journalctl >/dev/null 2>&1; then
        local output
        output="$(journalctl -b -1 -p warning..alert --no-pager | tail -200)"
        if [ -n "$output" ]; then
            echo "$output"
        else
            echo "No warning/error journal entries found for the previous boot."
            echo "Check available boots with: journalctl --list-boots"
        fi
    else
        echo "journalctl is not available; check /var/log/syslog* or /var/log/kern.log* manually."
        return 1
    fi
}

top-dirs-5() {
    local target="${1:-/}"
    sudo du -xhd1 "$target" 2>/dev/null | sort -hr | head -5
}

alias osver="cat /etc/os-release && uname -a"
alias chs="cat /etc/hosts"
alias crl="crontab -l"
alias cre="crontab -e"
alias ht="htop"
alias fr="free -hm"
alias pc='proxychains'
alias shad='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_rsa'
alias sshc='ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlPersist=10m'

# TCP traceroute report via mtr (package: mtr-tiny). Usage: mttr 1.2.3.4:443 [count]
mttr() {
    local target="${1:-}"
    local count="${2:-10}"
    local host port

    if ! command -v mtr >/dev/null 2>&1; then
        echo "Error: mtr is not installed (package: mtr-tiny)."
        echo "Install with: sudo apt install mtr-tiny   # or: sudo dnf install mtr"
        return 1
    fi

    if [ -z "$target" ]; then
        echo "Usage: mttr <host:port> [count]"
        echo "Example: mttr 1.1.1.1:443"
        echo "Example: mttr 1.1.1.1:443 5"
        return 1
    fi

    if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: count must be a positive integer (got: $count)"
        return 1
    fi

    # IPv6 bracket form: [2001:db8::1]:443
    if [[ "$target" =~ ^\[(.+)\]:([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    elif [[ "$target" =~ ^(.+):([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    else
        echo "Error: expected host:port (got: $target)"
        echo "Usage: mttr <host:port> [count]"
        return 1
    fi

    if [ -z "$host" ] || [ -z "$port" ]; then
        echo "Error: could not parse host/port from: $target"
        return 1
    fi

    mtr -TrnzP "$port" -c "$count" "$host"
}

# systemctl #########################################
# Alias for systemctl with auto-completion
alias sc='systemctl'
# Load the systemctl auto-completion function (ignore I/O errors on flaky FS)
if [ -r /usr/share/bash-completion/completions/systemctl ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/completions/systemctl >/dev/null 2>&1 || true
fi
if declare -F _systemctl >/dev/null 2>&1; then
    complete -F _systemctl sc
fi
alias scs='systemctl status'
alias scdr='systemctl daemon-reload'
alias scrl='systemctl reload'
alias scrs='systemctl restart'

# swap
alias swpfree="sudo swapoff -va && sudo swapon -va"

# show netstat 
alias nts='ss -ntulp'

# nginx ################################################
alias ngt='nginx -t'
alias ngr='nginx -t && systemctl reload nginx'
alias dngt='docker exec nginx nginx -t'
alias dngr='(docker exec nginx nginx -t) && (docker exec nginx nginx -s reload)'

# git ################################################
alias gs='git status'
alias gl='git log'
alias glp='git log --pretty=format:"%s"'
alias glon='git clone'
alias gp='git pull'
alias gc='git commit -S -m'
alias gdf='git diff'

# iptables ###########################################
alias fwl='sudo iptables -nvL --line-number'
alias fws='sudo iptables-save > /etc/iptables/rules.v4'
alias fwr='sudo iptables-restore /etc/iptables/rules.v4'

# pm2 #############################################
alias pml='pm2 ls'
alias pmrl='pm2 reload'
alias pmrs='pm2 restart'
alias pmlg='pm2 logs'
alias pmm='pm2 monit'
alias pmd='pm2 desc'
alias pms='pm2 save && pm2 startup'

# docker #############################################
alias d="docker"
# Load the docker auto-completion function (ignore I/O errors on flaky FS)
if [ -r /usr/share/bash-completion/completions/docker ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/completions/docker >/dev/null 2>&1 || true
fi
if declare -F _docker >/dev/null 2>&1; then
    complete -F _docker d
fi

# docker-compose
alias dc='docker compose'
# Fast path: source completion if already installed. Missing file is fetched
# asynchronously so network/sudo never blocks the prompt.
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

alias dps="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'"
alias wdps="watch \"docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'\""
alias dtop='docker stats'
alias dlf='docker logs -f'
alias dlog='docker ps -q | xargs -L 1 -P $(docker ps | wc -l) docker logs --since 30s --follow'
alias dim='docker images'
alias ddf='docker system df'
alias dprune='docker system prune -af --volumes'
alias dex='docker exec -it'
dsh() {
    local container="${1:-}"
    if [ -z "$container" ]; then
        echo "Usage: dsh <container>"
        return 1
    fi
    if docker exec "$container" bash -c 'exit 0' >/dev/null 2>&1; then
        docker exec -it "$container" bash
    else
        docker exec -it "$container" sh
    fi
}
alias dcps='docker compose ps -a'
alias dctop='docker compose top'
alias dceve='docker compose events'

# K8s ################################################
alias k='kubectl'
alias kg='kubectl get'

## Context / namespace
alias kx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config current-context'
alias kgno='kubectl get nodes -o wide'
alias kgpw='kubectl get pods -o wide --watch'

## Pods
alias kgpo='kubectl get pods -o wide'
alias kgpoj='kubectl get pods -o=json'
alias kgpon='kubectl get pods --namespace'

## Namespace Specific
alias ksysgpooyamll='kubectl --namespace=kube-system get pods -o=yaml -l'

## Deployments
alias kgd='kubectl get deploy' # deploy is the short name of the deployment

## Services
alias kgs='kubectl get svc'

## Create, Run, Apply, Delete, Describe
alias kc='kubectl create'
alias kr='kubectl run'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'
alias kdes='kubectl describe'

## Port Forwarding
alias kpf='kubectl port-forward'

# kubectl completion for alias k (when available)
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


################  bashrc Autoupdate  #################
# curl -sL -o ~/.bashrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/bashrc && . ~/.bashrc
######################################################
