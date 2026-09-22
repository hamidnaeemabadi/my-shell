#!/usr/bin/env bash
# shellcheck disable=SC2148
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# Apply shell configs to the current user.
# Existing files are copied to ~/.my-shell-backups/<timestamp>/ first.
set -euo pipefail

REPO_RAW="${MY_SHELL_RAW:-https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main}"
TPM_REPO="https://github.com/tmux-plugins/tpm"

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${HOME}/.my-shell-backups/${TIMESTAMP}"
BACKED_UP=0

if [ -t 1 ]; then
    C_CYAN='\033[1;36m'
    C_GREEN='\033[1;32m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[1;31m'
    C_RESET='\033[0m'
else
    C_CYAN=''
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
    C_RESET=''
fi

info() { printf '%b==>%b %s\n' "$C_CYAN" "$C_RESET" "$*"; }
ok()   { printf '%b  +%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%b  !%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
die()  { printf '%berror:%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

is_local() {
    [ -n "$SCRIPT_DIR" ] && [ -f "${SCRIPT_DIR}/bashrc" ] && [ -f "${SCRIPT_DIR}/tmux.conf" ]
}

download() {
    local url="$1"
    local dest="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 --retry-delay 1 -o "$dest" "$url"
        return
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$dest" "$url"
        return
    fi
    die "need curl or wget to download configs"
}

backup_if_exists() {
    local src="$1"
    [ -e "$src" ] || [ -L "$src" ] || return 0

    local rel="${src#"$HOME"/}"
    local dest="${BACKUP_ROOT}/${rel}"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    BACKED_UP=1
    ok "backed up ${src} -> ${dest}"
}

install_file() {
    local name="$1"
    local dest="$2"
    local tmp

    backup_if_exists "$dest"
    mkdir -p "$(dirname "$dest")"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN

    if is_local && [ -f "${SCRIPT_DIR}/${name}" ]; then
        cp -a "${SCRIPT_DIR}/${name}" "$tmp"
    else
        download "${REPO_RAW}/${name}" "$tmp"
    fi

    mv "$tmp" "$dest"
    trap - RETURN
    ok "installed ${dest}"
}

# Merge SSH defaults into ~/.ssh/config without wiping Host/ProxyJump entries.
# Managed block is between "# BEGIN my-shell" and "# END my-shell", appended last
# so first-match ssh_config rules still prefer earlier host-specific options.
install_ssh_config() {
    local dest="${HOME}/.ssh/config"
    local name="ssh_config"
    local begin="# BEGIN my-shell"
    local end="# END my-shell"
    local src_tmp out_tmp

    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    src_tmp="$(mktemp)"
    out_tmp="$(mktemp)"
    trap 'rm -f "$src_tmp" "$out_tmp"' RETURN

    if is_local && [ -f "${SCRIPT_DIR}/${name}" ]; then
        cp -a "${SCRIPT_DIR}/${name}" "$src_tmp"
    else
        download "${REPO_RAW}/${name}" "$src_tmp"
    fi

    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        cat "$src_tmp" > "$dest"
        chmod 600 "$dest"
        trap - RETURN
        rm -f "$src_tmp" "$out_tmp"
        ok "installed ${dest}"
        return 0
    fi

    backup_if_exists "$dest"

    if grep -Fxq "$begin" "$dest" && grep -Fxq "$end" "$dest"; then
        awk -v b="$begin" -v e="$end" '
            $0 == b { skip=1; next }
            skip && $0 == e { skip=0; next }
            !skip { print }
        ' "$dest" > "$out_tmp"
    else
        cat "$dest" > "$out_tmp"
    fi

    if [ -s "$out_tmp" ]; then
        # Ensure a blank line between existing config and the managed block.
        if [ "$(tail -c 1 "$out_tmp" | wc -l)" -eq 0 ]; then
            printf '\n' >> "$out_tmp"
        fi
        printf '\n' >> "$out_tmp"
    fi
    cat "$src_tmp" >> "$out_tmp"

    mv "$out_tmp" "$dest"
    chmod 600 "$dest"
    trap - RETURN
    rm -f "$src_tmp"
    ok "merged SSH defaults into ${dest}"
}

install_tpm() {
    local dest="${HOME}/.tmux/plugins/tpm"

    if [ -d "${dest}/.git" ] || [ -x "${dest}/tpm" ] || [ -f "${dest}/tpm" ]; then
        ok "tmux plugin manager already present (${dest})"
        return 0
    fi
    if ! command -v git >/dev/null 2>&1; then
        warn "git not found; skip tmux plugin manager (needed by ~/.tmux.conf)"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    if git clone --depth 1 "$TPM_REPO" "$dest" >/dev/null 2>&1; then
        ok "installed tmux plugin manager -> ${dest}"
    else
        warn "could not clone tmux plugin manager (needed by ~/.tmux.conf)"
    fi
}

info "Installing my-shell configs for ${USER:-$HOME}"
if is_local; then
    info "Using local files from ${SCRIPT_DIR}"
else
    info "Downloading files from ${REPO_RAW}"
fi

install_file bashrc "${HOME}/.bashrc"
install_file inputrc "${HOME}/.inputrc"
install_file vimrc "${HOME}/.vimrc"
install_file tmux.conf "${HOME}/.tmux.conf"
install_file htoprc "${HOME}/.config/htop/htoprc"
install_file kube-ps1.sh "${HOME}/.local/share/kube-ps1/kube-ps1.sh"
install_ssh_config
install_tpm

printf '\n'
if [ "$BACKED_UP" -eq 1 ]; then
    info "Previous configs saved in ${BACKUP_ROOT}"
    info "Restore example:  cp ${BACKUP_ROOT}/.bashrc ~/.bashrc"
else
    info "No existing configs to back up"
fi
info "Reload this shell with:  source ~/.bashrc"
info "In tmux, prefix is Ctrl-z; press prefix then I to install plugins"
ok "Done"
