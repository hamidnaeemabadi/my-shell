# My Custom Shell (bash + zsh)

Shared tooling for interactive **bash** and **zsh**, with shell-specific configs and one portable alias/function library.

## Layout

```text
my-shell/
  bashrc                 # bash-only: shopt, PROMPT_COMMAND, bind, complete
  zshrc                  # zsh-only: Oh My Zsh + Antigen, setopt, bindkey
  themes/my-shell.zsh-theme  # zsh prompt matching bash my_prompt
  shell/common.sh        # shared aliases + portable functions
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

```bash
cp ~/.my-shell-backups/<timestamp>/.bashrc ~/.bashrc
```

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
