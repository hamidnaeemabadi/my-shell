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

# append to the history file, don't overwrite it
shopt -s histappend

# auto cd to the directory
shopt -s autocd

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# HISTSIZE=1000
# HISTFILESIZE=2000

HISTSIZE=36000
SAVEHIST=36000
HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

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
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
else
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]\$\n '
fi

function my_prompt {
    local retval=$?
    local field3='$([ \j -gt 0 ] && echo \ jobs:\j)'"$(echo \ exit:$retval)"
    
    # PS1=$'\n'"\e[0;35m${field1}\e[m \e[0;34m${field2}\e[m\e[0;31m${field3}\e[m"$'\n'"\[\e[0;36m\]${field4}\[\e[m\] "
    
    PS1="${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\u@\H]\[\033[00m\]\[\033[01;34m\][\w]\[\033[01;35m\][\t]\[\033[00;00m\]${field3}\$\n "
}
PROMPT_COMMAND="my_prompt; ${PROMPT_COMMAND}"

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

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# My Editor
export VISUAL=vim
export EDITOR=vim

# Bash autocompletion
source /etc/profile.d/bash_completion.sh
bind -f ~/.inputrc
bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'

# My custom aliases
alias ll='ls -larth --group-directories-first'
alias l='ls -larth --group-directories-first'
alias lper="stat -c '%a %n' *"
alias la='ls -A'
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias where=which
alias hosts="sudo $EDITOR /etc/hosts" 
alias cls='clear'
alias lip='ip -o -4 addr show | awk '\''{print $2, $4}'\'''
alias myip='curl -s http://ip-api.com/line/"$(curl -s icanhazip.com)"'
alias update='sudo apt update && sudo apt upgrade -y'
alias less='less -NR'
alias v="vim"
alias osver="cat /etc/os-release"

# systemctl #########################################
# Alias for systemctl with auto-completion
alias sc='systemctl'
# Load the systemctl auto-completion function
if [ -r /usr/share/bash-completion/completions/systemctl ]; then
    . /usr/share/bash-completion/completions/systemctl
fi
# Apply auto-completion to the alias
complete -F _systemctl sc
alias scs='systemctl status'
alias scdr='systemctl daemon-reload'
alias scrl='systemctl reload'
alias scrs='systemctl restart'

# swap
alias swpfree="sudo swapoff -va && sudo swapon -va"

# show netstat 
alias nts='netstat -ntulp'

# git ################################################
alias gs='git status'
alias gl='git log'
alias glp='git log --pretty=format:"%s"'
alias glon='git clone'
alias gp='git pull'
alias gc='git commit -S -m'

# iptables ###########################################
alias fwl='sudo iptables -nvL --line-number'
alias fws='sudo iptables-save > /etc/iptables/rules.v4'
alias fwr='sudo iptables-restore /etc/iptables/rules.v4'

# docker #############################################
alias d="docker"
# Load the docker auto-completion function
if [ -r /usr/share/bash-completion/completions/docker ]; then
    . /usr/share/bash-completion/completions/docker
fi
# Apply auto-completion to the alias
complete -F _docker d

# docker-compose 
alias dc='docker compose'
# Download and install docker-compose auto-completion
DC_AUTOBASH_COMPLETE_FILE="/etc/bash_completion.d/docker-compose"
if [ ! -f "$DC_AUTOBASH_COMPLETE_FILE" ]; then
    sudo curl -sL https://raw.githubusercontent.com/docker/compose/1.23.2/contrib/completion/bash/docker-compose -o "$DC_AUTOBASH_COMPLETE_FILE"
fi
# Source the docker-compose auto-completion script
if [ -r /etc/bash_completion.d/docker-compose ]; then
    . /etc/bash_completion.d/docker-compose
fi
# Apply auto-completion to the alias
complete -F _docker_compose dc

alias dps="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'"
alias dtop='docker stats'
alias dlf='docker logs -f'
alias dlog='docker ps -q | xargs -L 1 -P $(docker ps | wc -l) docker logs --since 30s --follow'
alias dim='docker images'
alias ddf='docker system df'
alias dcps='docker compose ps -a'
alias dctop='docker compose top'
alias dceve='docker compose events'

# K8s ################################################
alias k='kubectl'
alias kg='kubectl get'

## Pods
alias kgpo='kubectl get pods'
alias kgpoojson='kubectl get pods -o=json'
alias kgpon='kubectl get pods --namespace'

## Namespace Specific
alias ksysgpooyamll='kubectl --namespace=kube-system get pods -o=yaml -l'

## Deployments
alias kgd='kubectl get deploy' # deploy is the short name of deployment

## Services
alias kgs='kubectl get svc'

## Create, Run, Apply, Delete
alias kc='kubectl create'
alias kr='kubectl run'
alias ka='kubectl apply -f'
alias kd='kubectl delete'

## Port Forwarding
alias kpf='kubectl port-forward'

## Describe
alias kd='kubectl describe'


################  bashrc Autoupdate  #################
curl -sL -o ~/.bashrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/bashrc
######################################################
