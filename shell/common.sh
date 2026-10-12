# shellcheck shell=sh
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# Shared aliases and portable helpers for bash and zsh.
# Sourced from ~/.bashrc and ~/.zshrc (installed to ~/.config/my-shell/common.sh).

# Editor
export VISUAL="${VISUAL:-vim}"
export EDITOR="${EDITOR:-vim}"

# ls / navigation
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

# Run ls after cd (bash/zsh both support builtin cd).
cd() {
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

# Package managers
alias apt='sudo apt'
alias nala='sudo nala'
alias dnf='sudo dnf'
alias yum='sudo yum'
alias qproxy='sudo qproxy'

# Homebrew (macOS / Linuxbrew) — never run brew with sudo
alias bi='brew install'
alias bun='brew uninstall'
alias bre='brew reinstall'
alias bup='brew update && brew upgrade && brew cleanup'
alias bupc='brew update && brew upgrade --greedy && brew cleanup'
alias bout='brew outdated'
alias bls='brew list'
alias bse='brew search'
alias binf='brew info'
alias bdr='brew doctor'
alias bcl='brew cleanup -s'
alias bpin='brew pin'
alias bunpin='brew unpin'
alias bservices='brew services'
alias bsl='brew services list'
# Casks (macOS GUI apps)
alias bci='brew install --cask'
alias bcu='brew uninstall --cask'
alias bcls='brew list --cask'
alias bcse='brew search --cask'

# Quick brew leave / deps helpers
brew-deps() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "brew is not installed (https://brew.sh)"
        return 1
    fi
    if [ -z "${1:-}" ]; then
        echo "Usage: brew-deps <formula>"
        return 1
    fi
    brew deps --tree --installed "$1"
}

brew-uses() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "brew is not installed (https://brew.sh)"
        return 1
    fi
    if [ -z "${1:-}" ]; then
        echo "Usage: brew-uses <formula>"
        return 1
    fi
    brew uses --installed "$1"
}

update() {
    printf 'Update packages? [y/N] '
    read -r _answer
    case "$_answer" in
        y|Y) ;;
        *) echo "Aborted."; return 0 ;;
    esac

    # macOS → Homebrew first; Linux → native PM, then Linuxbrew if present
    if [ "$(uname -s 2>/dev/null)" = Darwin ] && command -v brew >/dev/null 2>&1; then
        brew update && brew upgrade && brew cleanup
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt upgrade -y
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf upgrade -y
    elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y
    elif command -v brew >/dev/null 2>&1; then
        brew update && brew upgrade && brew cleanup
    else
        echo "No supported package manager found (brew/apt/dnf/yum)"
    fi
}

alias less='less -NR'
alias v="vim"
alias tf="tail -f"

fdns() {
    if [ "$(uname -s 2>/dev/null)" = Darwin ]; then
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder 2>/dev/null || true
        echo "macOS DNS caches flushed"
    elif command -v resolvectl >/dev/null 2>&1; then
        sudo resolvectl flush-caches && sudo resolvectl statistics
    elif command -v systemd-resolve >/dev/null 2>&1; then
        sudo systemd-resolve --flush-caches && sudo systemd-resolve --statistics
    elif command -v nscd >/dev/null 2>&1; then
        sudo nscd -i hosts
    else
        echo "No supported DNS cache manager found"
    fi
}

# Portable DNS probe list (no bash arrays).
dns-test() {
    domain="${1:-}"
    query_timeout=5

    if ! command -v nslookup >/dev/null 2>&1; then
        echo "Error: nslookup is required but not installed."
        return 1
    fi

    if [ -z "$domain" ]; then
        printf 'Enter domain to test: '
        read -r domain
    fi

    if [ -z "$domain" ]; then
        echo "Error: domain is required."
        echo "Usage: dns-test <domain>"
        return 1
    fi

    echo "Testing DNS resolution for: $domain"
    echo "------------------------------------"

    while IFS='|' read -r name ip; do
        [ -n "$name" ] || continue
        result="$(timeout "${query_timeout}" nslookup "$domain" "$ip" 2>/dev/null)"
        status=$?

        if [ "$status" -eq 124 ]; then
            echo "⏱️  $name ($ip) -> TIMEOUT after ${query_timeout}s"
        elif echo "$result" | grep -q "Address:"; then
            resolved="$(echo "$result" | grep "Address:" | tail -n1 | awk '{print $2}')"
            echo "✅ $name ($ip) -> $resolved"
        else
            echo "❌ $name ($ip) -> FAILED"
        fi
        sleep 2
    done <<'EOF'
tci|5.200.200.200
recursive1.dci.ir|217.218.127.127
recursive2.dci.ir|217.218.155.155
pns01.afranet.ir|79.175.137.4
pns02.afranet.ir|79.175.136.4
dns1.begzar.ir|185.55.224.24
dns2.begzar.ir|185.55.226.26
dns3.begzar.ir|185.55.225.25
dns.electro1|78.157.42.100
dns.electro2|78.157.42.101
DNS|178.252.149.220
recursive1.dnspro.ir|87.107.110.109
recursive2.dnspro.ir|87.107.110.110
free.shecan.ir|178.22.122.100
dns.shecan.ir|185.51.200.2
403.online1|10.202.10.202
403.online2|10.202.10.102
403.online3|10.202.10.10
403.online4|10.202.10.11
dns94-1|94.103.125.157
dns94-2|94.103.125.158
beshkan1|181.41.194.177
beshkan2|181.41.194.186
dns5-1|5.202.100.100
dns5-2|5.202.100.101
level3-1|209.244.0.3
level3-2|209.244.0.4
dns85-1|85.15.1.14
dns85-2|85.15.1.15
EOF
}

unalias random-password 2>/dev/null || true
random-password() {
    length="${1:-}"

    if [ -z "$length" ]; then
        printf 'Enter password length [48]: '
        read -r length
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
    target="${1:-/}"
    sudo du -xhd1 "$target" 2>/dev/null | sort -hr | head -5
}

alias osver="cat /etc/os-release && uname -a"
alias chs="cat /etc/hosts"
alias crl="crontab -l"
alias cre="crontab -e"
alias ht="htop"
alias fr="free -hm"
alias dfh='df -hT -x tmpfs -x devtmpfs'
alias dfi='df -ih -x tmpfs -x devtmpfs'
alias mounts='findmnt -D'
alias iow='sudo iostat -xz 1'
alias pc='proxychains'
alias shad='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_rsa'
alias sshc='ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlPersist=10m'

# TCP traceroute via mtr. Usage: mttr 1.2.3.4:443 [count]
# Portable host:port parse (no BASH_REMATCH).
mttr() {
    target="${1:-}"
    count="${2:-10}"
    host=""
    port=""

    if ! command -v mtr >/dev/null 2>&1; then
        echo "Error: mtr is not installed (package: mtr-tiny)."
        echo "Install with: sudo apt install mtr-tiny  |  sudo dnf install mtr  |  brew install mtr"
        return 1
    fi

    if [ -z "$target" ]; then
        echo "Usage: mttr <host:port> [count]"
        echo "Example: mttr 1.1.1.1:443"
        return 1
    fi

    case "$count" in
        ''|*[!0-9]*)
            echo "Error: count must be a positive integer (got: $count)"
            return 1
            ;;
    esac
    if [ "$count" -lt 1 ]; then
        echo "Error: count must be a positive integer (got: $count)"
        return 1
    fi

    case "$target" in
        \[*\]:*)
            host="${target#\[}"
            host="${host%%\]*}"
            port="${target##*:}"
            ;;
        *:*)
            host="${target%:*}"
            port="${target##*:}"
            ;;
        *)
            echo "Error: expected host:port (got: $target)"
            echo "Usage: mttr <host:port> [count]"
            return 1
            ;;
    esac

    case "$port" in
        ''|*[!0-9]*)
            echo "Error: could not parse host/port from: $target"
            return 1
            ;;
    esac

    if [ -z "$host" ]; then
        echo "Error: could not parse host/port from: $target"
        return 1
    fi

    mtr -TrnzP "$port" -c "$count" "$host"
}

# systemctl / journalctl
alias sc='systemctl'
alias scs='systemctl status'
alias scdr='systemctl daemon-reload'
alias scrl='systemctl reload'
alias scrs='systemctl restart'
alias scf='systemctl --failed'
alias scu='systemctl list-units --type=service --state=running'
alias jc='journalctl'
alias jcu='journalctl -u'
alias jce='journalctl -xe'
alias jcf='journalctl -f'
alias jcerr='journalctl -p err -b'

alias swpfree="sudo swapoff -va && sudo swapon -va"

# ports / listening
alias nts='ss -ntulp'
alias listening='ss -lntup'
port() { ss -lntup | grep -E -- "$1"; }
pidof-port() { ss -lntp | grep ":$1 "; }
fuser-port() { sudo fuser -v "${1}/tcp"; }

# nginx
alias ngt='nginx -t'
alias ngr='nginx -t && systemctl reload nginx'
alias dngt='docker exec nginx nginx -t'
alias dngr='(docker exec nginx nginx -t) && (docker exec nginx nginx -s reload)'

# git (override OMZ git plugin aliases when both are loaded)
alias gs='git status'
alias gl='git log'
alias glp='git log --pretty=format:"%s"'
alias glon='git clone'
alias gp='git pull'
alias gc='git commit -S -m'
alias gdf='git diff'

# iptables
alias fwl='sudo iptables -nvL --line-number'
alias fws='sudo iptables-save > /etc/iptables/rules.v4'
alias fwr='sudo iptables-restore /etc/iptables/rules.v4'

# pm2
alias pml='pm2 ls'
alias pmrl='pm2 reload'
alias pmrs='pm2 restart'
alias pmlg='pm2 logs'
alias pmm='pm2 monit'
alias pmd='pm2 desc'
alias pms='pm2 save && pm2 startup'

# docker
alias d="docker"
alias dc='docker compose'
alias dps="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'"
alias wdps="watch \"docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'\""
alias dtop='docker stats'
alias dlf='docker logs -f'
alias dlog='docker ps -q | xargs -L 1 -P $(docker ps | wc -l) docker logs --since 30s --follow'
alias dim='docker images'
alias ddf='docker system df'
alias dprune='docker system prune -af --volumes'
alias dex='docker exec -it'
alias dcps='docker compose ps -a'
alias dctop='docker compose top'
alias dceve='docker compose events'

dsh() {
    container="${1:-}"
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

# kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config current-context'
alias kgno='kubectl get nodes -o wide'
alias kgpw='kubectl get pods -o wide --watch'
alias kgpo='kubectl get pods -o wide'
alias kgpoj='kubectl get pods -o=json'
alias kgpon='kubectl get pods --namespace'
alias ksysgpooyamll='kubectl --namespace=kube-system get pods -o=yaml -l'
alias kgd='kubectl get deploy'
alias kgs='kubectl get svc'
alias kc='kubectl create'
alias kr='kubectl run'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'
alias kdes='kubectl describe'
alias kga='kubectl get all,ing,cm,secret,pvc'
alias kgev='kubectl get events --sort-by=.lastTimestamp'
alias ktop='kubectl top pods'
alias ktn='kubectl top nodes'
alias kdump='kubectl cluster-info dump --output-directory=/tmp/k8s-dump'
alias kpf='kubectl port-forward'

kl()  { kubectl logs -f --tail=100 "$@"; }
kex() { kubectl exec -it "$1" -- "${2:-bash}"; }
kroll() { kubectl rollout restart "$@"; kubectl rollout status "$@"; }
