# My Custom Shell (bash + zsh)

Shared tooling for interactive **bash** and **zsh**, with shell-specific configs and one portable alias/function library.

## Layout

```text
my-shell/
  bashrc                 # bash-only: shopt, PROMPT_COMMAND, bind, complete
  zshrc                  # zsh-only: Oh My Zsh + Antigen, setopt, bindkey
  themes/my-shell.zsh-theme  # zsh prompt matching bash my_prompt
  shell/common.sh        # shared aliases + portable functions
  nvim/init.vim          # Neovim version of vimrc
  scripts/install-htop.sh
  install.sh             # detects login shell; installs matching + shared configs
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/install.sh | bash
```

Or from a local clone:

```bash
git clone https://github.com/hamidnaeemabadi/my-shell.git
cd my-shell
./install.sh
```

### Shell target

The installer detects your login shell (`$SHELL`) and installs that shell’s configs plus shared files.

| `MY_SHELL_TARGET` | Behavior |
|-------------------|----------|
| `auto` (default)  | Login shell only (`bash` or `zsh`) |
| `bash`            | Bash configs + shared |
| `zsh`             | Zsh configs + Oh My Zsh plugins + shared |
| `all`             | Both shells + shared |

Examples:

```bash
MY_SHELL_TARGET=zsh ./install.sh
MY_SHELL_TARGET=all ./install.sh
```

Then reload:

```bash
# bash
source ~/.bashrc

# zsh
source ~/.zshrc
```

### What gets installed

**Always (shared)**

- `~/.config/my-shell/common.sh`
- `~/.vimrc`
- Basic Neovim config and workstation detector in `${XDG_CONFIG_HOME:-~/.config}/nvim/`; plugin configuration and lockfile only on verified workstations
- `~/.tmux.conf`
- `~/.config/htop/htoprc`
- `~/.local/share/kube-ps1/kube-ps1.sh`
- SSH defaults merged into `~/.ssh/config` (existing Host entries kept)
- tmux plugin manager (`~/.tmux/plugins/tpm`) if `git` is available

**Bash** (`MY_SHELL_TARGET=bash|auto` when login is bash, or `all`)

- `~/.bashrc`
- `~/.inputrc`

**Zsh** (`MY_SHELL_TARGET=zsh|auto` when login is zsh, or `all`)

- `~/.zshrc`
- Oh My Zsh (`~/.oh-my-zsh`) if missing
- Oh My Zsh plugins (see `zshrc`): `git`, `docker`, `kubectl`, `kube-ps1`, `systemd`, `ssh-agent`, `fzf`, `tmux`, …
- [Antigen](https://github.com/zsh-users/antigen) (`~/.antigen.zsh` via [git.io/antigen](https://git.io/antigen)) for third-party bundles (`zsh-autosuggestions`, `zsh-syntax-highlighting`, …)

Previous files are copied to `~/.my-shell-backups/<timestamp>/` first.
An existing Neovim `init.lua` is also backed up and removed after `init.vim` is
installed, so Neovim loads the new configuration without a startup conflict.

```bash
cp ~/.my-shell-backups/<timestamp>/.bashrc ~/.bashrc
```

## Neovim for DevOps

Plugins are installed and loaded **only on verified workstations**. The installer
and Neovim startup use the same check, with no force-install override:

- macOS is allowed.
- Ubuntu requires an installed `ubuntu-desktop` or `ubuntu-desktop-minimal` package.
- Fedora requires `VARIANT_ID=workstation` and the `fedora-release-workstation` package.
- Both Linux cases also require a confirmed non-container environment,
  `graphical.target` as the default systemd target, and a loaded
  `display-manager.service`.
- Linux servers, other distributions/desktop variants, missing evidence and
  detection errors skip plugins. `DISPLAY` and desktop session variables do not
  qualify a system. SSH access to a verified workstation is allowed.

Basic editor settings are still installed everywhere. Existing plugin files and
caches on excluded systems are left untouched, but this config does not load
them or download plugins.

Plugins require **Neovim 0.11.3+** and **Git**. On first launch, lazy.nvim downloads
the plugins; internet access is needed. The included `lazy-lock.json` records
the tested plugin versions. Use `:Lazy restore` to restore those versions or
`:Lazy update` to update them. Re-running the installer backs up and replaces
the installed config and lockfile.

The five configured plugins are:

- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig): Bash, YAML, Terraform, Ansible, Dockerfile and JSON language support, with native completion.
- [nvim-lint](https://github.com/mfussenegger/nvim-lint): ShellCheck, yamllint and ansible-lint on file open and save.
- [conform.nvim](https://github.com/stevearc/conform.nvim): manual formatting with shfmt, terraform fmt and Prettier.
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim): changed-line signs, hunk previews and staging.
- [snacks.nvim](https://github.com/folke/snacks.nvim): file search, repository search, explorer and diagnostic picker.

The installer installs configuration, not external development tools. Install
the tools you need on your PATH, then restart Neovim:

- Language servers: `bash-language-server`, `yaml-language-server`, `terraform-ls`, `ansible-language-server`, `docker-langserver`, `vscode-json-language-server`.
- Linters: `shellcheck`, `yamllint`, `ansible-lint`.
- Formatters: `shfmt`, `terraform`, `prettier`.
- Search: `rg` (ripgrep), and optionally `fd`.

Run `:DevOpsTools` to see which executables are available. Missing tools are
skipped; `:checkhealth vim.lsp`, `:ConformInfo` and `:checkhealth snacks` provide
more detail. Bash and Ansible language servers delegate their standalone lint
checks to nvim-lint to avoid duplicate diagnostics.

The leader key is **Space**:

- `Space ff`: find files; `Space fg`: search contents; `Space e`: explorer.
- `Space xx`: list diagnostics; `Space d`: explain a diagnostic under the cursor.
- `Space cf`: format the buffer or visual selection; formatting on save is disabled.
- `Space hp`: preview a Git hunk; `Space hs`: stage a hunk; `[h` / `]h`: previous/next hunk.
- With an attached language server: `gd`: definition; `K`: hover; `Space ca`: code action; `Space rn`: rename.
- Native completion supports `Ctrl-x Ctrl-o`, with automatic triggering where supported by the server.

YAML uses two-space indentation, including Ansible files under `playbooks/`
and role `tasks/` and `handlers/` directories. For other Ansible layouts, use
`:setfiletype yaml.ansible`. Chart YAML under `templates/` is detected as `helm`
when a parent `Chart.yaml` exists and is excluded from generic YAML linting and
formatting. Kubernetes schemas are not forced onto every YAML file: select a
schema matching your cluster using a YAML language-server `$schema` comment.

Run `python3 tests/test-workstation.py` for the OS detection matrix and server
startup checks, and `bash tests/test-neovim-install.sh` for isolated workstation
installer tests. To also
test the real plugins without downloads, set `MY_SHELL_PLUGIN_CACHE` to a
populated lazy.nvim plugin directory (normally `~/.local/share/nvim/lazy`).

## Zsh feature mapping (no reinventing)

| Bash feature | Zsh approach |
|--------------|--------------|
| Custom prompt + git | Theme `my-shell` + OMZ `git` plugin |
| kube-ps1 | OMZ `kube-ps1` plugin on `RPROMPT` |
| ssh-agent / `shad` | OMZ `ssh-agent` plugin (loads `id_rsa`) |
| kubectl / docker / systemd / pm2 | OMZ plugins + `shell/common.sh` short aliases |
| apt / dnf helpers | OMZ `debian` / `ubuntu` / `dnf` plugins |
| Command elapsed time | Builtin `REPORTTIME` / `TIMEFMT` |
| History / erasedups | `setopt SHARE_HISTORY HIST_IGNORE_*` |
| autocd / globstar | `setopt AUTO_CD EXTENDED_GLOB` |
| Completion UX | OMZ `compinit` + `zstyle` / `bindkey` |
| Autosuggest / highlight | Antigen bundles (or distro packages) |
| Directory jump / fuzzy find | OMZ `z` + `fzf` |
| tmux / sudo / thefuck / tldr | OMZ plugins |

Aliases and helpers (`sc*`, `jc*`, `k*`, `mttr`, `port`, …) live in `shell/common.sh` and are sourced by both shells.

Terminate processes matching a port with `kill-port` (requires `lsof`):

```bash
kill-port 8080       # TCP and UDP
kill-port 8080 tcp   # TCP only
kill-port 5353 udp   # UDP only
```

This sends SIGTERM without sudo. Like `lsof -i`, it matches listening and
connected sockets, including connections to the selected remote port. Invalid
ports/protocols are rejected; no signal is sent when no processes match.

## Zsh plugins with Antigen

[Antigen](https://github.com/zsh-users/antigen) is installed to `~/.antigen.zsh` ([git.io/antigen](https://git.io/antigen)). Oh My Zsh still owns the `plugins=(…)` list; Antigen is for extra GitHub/OMZ bundles declared in `~/.zshrc`.

### Ready-to-run commands

```bash
# Show loaded Antigen bundles
antigen list

# Update all Antigen bundles
antigen update

# Update Antigen itself
antigen selfupdate

# Remove unused cloned repos
antigen cleanup

# Clear Antigen cache after editing ~/.zshrc (then reload)
antigen reset
exec zsh
```

### Add a new plugin

1. Edit `~/.zshrc` and add a line under the Antigen section, for example:

```zsh
antigen bundle zsh-users/zsh-completions
# antigen bundle djui/alias-tips
# antigen bundle Aloxaf/fzf-tab
```

2. Apply and reload:

```bash
antigen reset
source ~/.zshrc
# or: exec zsh
```

Sample bundles already enabled in `zshrc`: `zsh-users/zsh-autosuggestions`, `zsh-users/zsh-syntax-highlighting`. More samples are commented next to them.

## Optional: latest htop from source

Compile and install the newest htop release for your OS (Debian/Ubuntu, Fedora, RHEL/CentOS, Arch, openSUSE, macOS):

```bash
curl -fsSL https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/scripts/install-htop.sh | bash
```

Or from a local clone:

```bash
./scripts/install-htop.sh
htop -V
```

The script installs build dependencies, removes any packaged `htop`, builds the latest git tag, and runs `sudo make install`.
