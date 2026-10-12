#!/usr/bin/env bash
#################################################
#             By Hamid Naeemabadi               #
#  https://github.com/hamidnaeemabadi/my-shell  #
#################################################
# Build and install the latest htop release from source.
# Detects the target OS / package manager for build dependencies.
#
# Usage:
#   ./scripts/install-htop.sh
#   curl -fsSL https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/scripts/install-htop.sh | bash
set -euo pipefail

HTOP_REPO="${HTOP_REPO:-https://github.com/htop-dev/htop.git}"

if [ -t 1 ]; then
    C_CYAN='\033[1;36m'
    C_GREEN='\033[1;32m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[1;31m'
    C_RESET='\033[0m'
else
    C_CYAN='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

info() { printf '%b==>%b %s\n' "$C_CYAN" "$C_RESET" "$*"; }
ok()   { printf '%b  +%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%b  !%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
die()  { printf '%berror:%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "need '$1' but it was not found"
}

detect_os() {
    local uname_s
    uname_s="$(uname -s 2>/dev/null || echo unknown)"
    case "$uname_s" in
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                printf 'debian\n'
            elif command -v dnf >/dev/null 2>&1; then
                printf 'fedora\n'
            elif command -v yum >/dev/null 2>&1; then
                printf 'rhel\n'
            elif command -v pacman >/dev/null 2>&1; then
                printf 'arch\n'
            elif command -v zypper >/dev/null 2>&1; then
                printf 'suse\n'
            else
                printf 'linux-unknown\n'
            fi
            ;;
        Darwin)
            printf 'macos\n'
            ;;
        *)
            printf 'unsupported\n'
            ;;
    esac
}

install_build_deps() {
    local os="$1"
    info "Installing build dependencies (${os})"

    case "$os" in
        debian)
            sudo apt-get -qq update
            sudo apt-get install -y \
                build-essential libncursesw5-dev autotools-dev \
                autoconf automake git
            ;;
        fedora)
            sudo dnf install -y gcc make ncurses-devel autoconf automake git
            ;;
        rhel)
            sudo yum install -y gcc make ncurses-devel autoconf automake git
            ;;
        arch)
            sudo pacman -Sy --needed --noconfirm base-devel ncurses autoconf automake git
            ;;
        suse)
            sudo zypper install -y gcc make ncurses-devel autoconf automake git
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                die "Homebrew is required on macOS (https://brew.sh)"
            fi
            brew install autoconf automake ncurses git
            # Prefer Homebrew ncurses over the macOS SDK copy when configuring.
            export PATH="$(brew --prefix ncurses)/bin:${PATH}"
            export LDFLAGS="-L$(brew --prefix ncurses)/lib ${LDFLAGS:-}"
            export CPPFLAGS="-I$(brew --prefix ncurses)/include ${CPPFLAGS:-}"
            export PKG_CONFIG_PATH="$(brew --prefix ncurses)/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
            ;;
        *)
            die "unsupported OS/package manager; install gcc make ncurses autoconf automake git manually"
            ;;
    esac
    ok "build dependencies ready"
}

remove_packaged_htop() {
    local os="$1"
    info "Removing packaged htop (if present)"

    case "$os" in
        debian)
            sudo apt-get remove --purge -y htop 2>/dev/null || true
            ;;
        fedora)
            sudo dnf remove -y htop 2>/dev/null || true
            ;;
        rhel)
            sudo yum remove -y htop 2>/dev/null || true
            ;;
        arch)
            sudo pacman -Rns --noconfirm htop 2>/dev/null || true
            ;;
        suse)
            sudo zypper remove -y htop 2>/dev/null || true
            ;;
        macos)
            brew uninstall htop 2>/dev/null || true
            ;;
    esac
}

build_and_install() {
    local tmp tag
    need_cmd git
    need_cmd make

    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" EXIT

    info "Cloning htop (${HTOP_REPO})"
    git clone --quiet "$HTOP_REPO" "${tmp}/htop"
    cd "${tmp}/htop"

    tag="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
    info "Checking out latest release: ${tag}"
    git checkout --quiet "$tag"

    info "Configuring / building / installing"
    ./autogen.sh
    ./configure
    make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"
    sudo make install

    ok "htop ${tag} installed"
}

main() {
    local os
    os="$(detect_os)"
    info "Target OS profile: ${os}"

    if [ "$os" = unsupported ] || [ "$os" = linux-unknown ]; then
        die "could not detect a supported package manager on this system"
    fi

    install_build_deps "$os"
    remove_packaged_htop "$os"
    build_and_install

    if command -v htop >/dev/null 2>&1; then
        info "Installed version:"
        htop -V
        warn "Open a new shell (or hash -r) if an older htop is still hashed"
    else
        die "htop binary not found on PATH after install"
    fi
}

main "$@"
