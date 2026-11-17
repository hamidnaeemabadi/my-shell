#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

# Load installer functions without running shell/plugin installation.
sed '/^# ---- main ----/,$d' "$repo/install.sh" > "$test_root/installer-functions.sh"
# shellcheck disable=SC1091
source "$test_root/installer-functions.sh"
SCRIPT_DIR="$repo"
HOME="$test_root/home"
BACKUP_ROOT="$HOME/backups"
mkdir -p "$HOME"
unset XDG_CONFIG_HOME

install_neovim
cmp "$repo/nvim/init.vim" "$HOME/.config/nvim/init.vim"
cmp "$repo/nvim/lua/my_shell/plugins.lua" "$HOME/.config/nvim/lua/my_shell/plugins.lua"
cmp "$repo/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"

XDG_CONFIG_HOME="$test_root/custom config"
mkdir -p "$XDG_CONFIG_HOME/nvim"
printf 'old vim config\n' > "$XDG_CONFIG_HOME/nvim/init.vim"
printf 'old lua config\n' > "$XDG_CONFIG_HOME/nvim/init.lua"
install_neovim
cmp "$repo/nvim/init.vim" "$XDG_CONFIG_HOME/nvim/init.vim"
test ! -e "$XDG_CONFIG_HOME/nvim/init.lua"
grep -Fxq 'old vim config' "$BACKUP_ROOT/$XDG_CONFIG_HOME/nvim/init.vim"
grep -Fxq 'old lua config' "$BACKUP_ROOT/$XDG_CONFIG_HOME/nvim/init.lua"

if command -v nvim >/dev/null 2>&1; then
    # Simulate an offline bootstrap without making a network request.
    XDG_DATA_HOME="$test_root/offline-data" XDG_STATE_HOME="$test_root/state" \
        XDG_CACHE_HOME="$test_root/cache" NVIM_LOG_FILE="$test_root/nvim.log" \
        nvim --headless \
        --cmd 'lua local system = vim.fn.system; vim.fn.system = function() return system({"false"}) end' \
        -u "$XDG_CONFIG_HOME/nvim/init.vim" \
        -c 'lua if not vim.o.number or vim.v.errmsg ~= "" then vim.cmd("cquit") end' \
        -c 'qa!' > "$test_root/offline.log" 2>&1
    grep -Fq 'Could not download lazy.nvim' "$test_root/offline.log"
fi

# Optionally test the actual plugins using an already downloaded plugin cache.
if [ -n "${MY_SHELL_PLUGIN_CACHE:-}" ]; then
    mkdir -p "$test_root/data/nvim"
    cp -R "$MY_SHELL_PLUGIN_CACHE" "$test_root/data/nvim/lazy"
    XDG_DATA_HOME="$test_root/data" XDG_STATE_HOME="$test_root/state" \
        XDG_CACHE_HOME="$test_root/cache" NVIM_LOG_FILE="$test_root/nvim.log" \
        MY_SHELL_TEST_ROOT="$test_root" \
        nvim --headless -u "$XDG_CONFIG_HOME/nvim/init.vim" -l "$repo/tests/test-neovim-plugins.lua"
fi

# A failed download must leave the user's Lua config available.
printf 'keep lua config\n' > "$XDG_CONFIG_HOME/nvim/init.lua"
SCRIPT_DIR=""
download() { return 1; }
export HOME XDG_CONFIG_HOME BACKUP_ROOT SCRIPT_DIR REPO_RAW C_GREEN C_RESET
export -f backup_if_exists install_file install_neovim is_local download ok
if bash -eu -c install_neovim; then
    echo 'Expected installation failure' >&2
    exit 1
fi
grep -Fxq 'keep lua config' "$XDG_CONFIG_HOME/nvim/init.lua"

echo 'Neovim installation checks passed'
