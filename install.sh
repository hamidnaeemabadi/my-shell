#!/usr/bin/env bash
# shellcheck disable=SC2148
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# Apply shell configs to the current user.
# Existing files are copied to ~/.my-shell-backups/<timestamp>/ first.
#
# Shell selection (extensible):
#   MY_SHELL_TARGET=auto   # default: login shell from $SHELL (bash|zsh)
#   MY_SHELL_TARGET=bash   # bash configs only (+ shared)
#   MY_SHELL_TARGET=zsh    # zsh configs only (+ shared)
#   MY_SHELL_TARGET=all    # bash + zsh (+ shared)
#
# Shared always: vimrc, tmux, htop, kube-ps1, ssh_config, shell/common.sh
set -euo pipefail

REPO_RAW="${MY_SHELL_RAW:-https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main}"
TPM_REPO="https://github.com/tmux-plugins/tpm"
OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
# Antigen plugin manager (git.io/antigen) — used for third-party zsh bundles
ANTIGEN_URL="${ANTIGEN_URL:-https://git.io/antigen}"
ANTIGEN_URL_FALLBACK="https://raw.githubusercontent.com/zsh-users/antigen/develop/bin/antigen.zsh"
ANTIGEN_DEST="${ANTIGEN_DEST:-$HOME/.antigen.zsh}"

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

# Detect login shell basename: bash | zsh | other
detect_login_shell() {
    local shell_path shell_name
    shell_path="${SHELL:-}"
    if [ -z "$shell_path" ] && command -v getent >/dev/null 2>&1; then
        shell_path="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | awk -F: '{print $NF}')"
    fi
    shell_name="$(basename "${shell_path:-bash}")"
    case "$shell_name" in
        bash|zsh) printf '%s\n' "$shell_name" ;;
        *) printf 'bash\n' ;;  # safe default for shared tooling
    esac
}

# Resolve install target(s): bash, zsh, or both (space-separated)
resolve_shell_targets() {
    local target="${MY_SHELL_TARGET:-auto}"
    case "$target" in
        auto)
            detect_login_shell
            ;;
        bash|zsh)
            printf '%s\n' "$target"
            ;;
        all|both)
            printf '%s\n' "bash zsh"
            ;;
        *)
            die "MY_SHELL_TARGET must be auto|bash|zsh|all (got: $target)"
            ;;
    esac
}

target_includes() {
    local needle="$1"
    case " $SHELL_TARGETS " in
        *" $needle "*) return 0 ;;
        *) return 1 ;;
    esac
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

# Install repo-relative path to destination.
# Usage: install_file bashrc ~/.bashrc
#        install_file shell/common.sh ~/.config/my-shell/common.sh
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

install_oh_my_zsh() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

    if ! command -v zsh >/dev/null 2>&1; then
        warn "zsh not installed; skip Oh My Zsh (install zsh, then re-run with MY_SHELL_TARGET=zsh)"
        return 0
    fi

    if [ ! -d "$zsh_dir" ] || [ ! -f "$zsh_dir/oh-my-zsh.sh" ]; then
        if ! command -v git >/dev/null 2>&1; then
            warn "git not found; cannot install Oh My Zsh"
            return 0
        fi
        info "Installing Oh My Zsh -> ${zsh_dir}"
        # Non-interactive: keep any existing ~/.zshrc (we overwrite via install_file)
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OMZ_INSTALL_URL")" "" --unattended >/dev/null 2>&1 \
            || RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(wget -qO- "$OMZ_INSTALL_URL")" "" --unattended >/dev/null 2>&1 \
            || {
                warn "Oh My Zsh installer failed; clone manually if needed"
                return 0
            }
        ok "Oh My Zsh installed"
    else
        ok "Oh My Zsh already present (${zsh_dir})"
    fi
}

# Antigen — https://github.com/zsh-users/antigen (curl -L git.io/antigen)
install_antigen() {
    local dest="${ANTIGEN_DEST}"
    local tmp

    if [ -s "$dest" ]; then
        ok "antigen already present (${dest})"
        return 0
    fi

    info "Installing antigen -> ${dest}"
    tmp="$(mktemp)"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 "$ANTIGEN_URL" -o "$tmp" \
            || curl -fsSL --retry 3 "$ANTIGEN_URL_FALLBACK" -o "$tmp" \
            || {
                rm -f "$tmp"
                warn "could not download antigen"
                return 0
            }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$tmp" "$ANTIGEN_URL" \
            || wget -q -O "$tmp" "$ANTIGEN_URL_FALLBACK" \
            || {
                rm -f "$tmp"
                warn "could not download antigen"
                return 0
            }
    else
        warn "need curl or wget to install antigen"
        return 0
    fi

    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        warn "antigen download was empty"
        return 0
    fi

    mv "$tmp" "$dest"
    ok "installed antigen -> ${dest}"
}

install_shared() {
    info "Installing shared configs"
    install_file "shell/common.sh" "${HOME}/.config/my-shell/common.sh"
    install_file vimrc "${HOME}/.vimrc"
    install_file tmux.conf "${HOME}/.tmux.conf"
    install_file htoprc "${HOME}/.config/htop/htoprc"
    install_file kube-ps1.sh "${HOME}/.local/share/kube-ps1/kube-ps1.sh"
    install_ssh_config
    install_tpm
}

install_bash() {
    info "Installing bash configs"
    install_file bashrc "${HOME}/.bashrc"
    install_file inputrc "${HOME}/.inputrc"
    # Ensure undo dir for vimrc undofile (harmless if unused)
    mkdir -p "${HOME}/.vim/undo"
}

install_zsh() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
    local custom_dir="${ZSH_CUSTOM:-$zsh_dir/custom}"

    info "Installing zsh configs"
    install_oh_my_zsh
    install_antigen
    mkdir -p "${custom_dir}/themes"
    install_file "themes/my-shell.zsh-theme" "${custom_dir}/themes/my-shell.zsh-theme"
    install_file zshrc "${HOME}/.zshrc"
}

# ---- main ----
LOGIN_SHELL="$(detect_login_shell)"
SHELL_TARGETS="$(resolve_shell_targets)"

info "Installing my-shell configs for ${USER:-$HOME}"
info "Login shell: ${LOGIN_SHELL}  |  target(s): ${SHELL_TARGETS}  (override with MY_SHELL_TARGET=auto|bash|zsh|all)"
if is_local; then
    info "Using local files from ${SCRIPT_DIR}"
else
    info "Downloading files from ${REPO_RAW}"
fi

install_shared

if target_includes bash; then
    install_bash
fi
if target_includes zsh; then
    install_zsh
fi

printf '\n'
if [ "$BACKED_UP" -eq 1 ]; then
    info "Previous configs saved in ${BACKUP_ROOT}"
    info "Restore example:  cp ${BACKUP_ROOT}/.bashrc ~/.bashrc"
else
    info "No existing configs to back up"
fi

if target_includes bash && [ "$LOGIN_SHELL" = bash ]; then
    info "Reload this shell with:  source ~/.bashrc"
elif target_includes zsh && [ "$LOGIN_SHELL" = zsh ]; then
    info "Reload this shell with:  source ~/.zshrc"
elif target_includes zsh; then
    info "Zsh config installed. Switch with:  chsh -s \$(which zsh)   then:  source ~/.zshrc"
elif target_includes bash; then
    info "Reload with:  source ~/.bashrc"
fi

info "In tmux, prefix is Ctrl-z; press prefix then I to install plugins"
ok "Done"
