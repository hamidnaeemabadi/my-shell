# My Custom Bash Shell

## Install

Copy and run this command:

```bash
curl -fsSL https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.bashrc
```

The installer backs up any existing files to `~/.my-shell-backups/<timestamp>/`, then applies:

- `~/.bashrc`
- `~/.inputrc`
- `~/.vimrc`
- `~/.tmux.conf`
- `~/.config/htop/htoprc`
- `~/.local/share/kube-ps1/kube-ps1.sh`
- tmux plugin manager (`~/.tmux/plugins/tpm`) if `git` is available

Restore a previous file from the backup directory, for example:

```bash
cp ~/.my-shell-backups/<timestamp>/.bashrc ~/.bashrc
```

### Install from a local clone

```bash
git clone https://github.com/hamidnaeemabadi/my-shell.git
cd my-shell
./install.sh
```

## Optional: latest htop from source

If your htop is not the latest version, you can compile it from source (open a new shell to use the new htop):

```bash
if command -v apt-get &>/dev/null; then
sudo apt-get -qq update && sudo apt-get install -y build-essential libncursesw5-dev autotools-dev \
          autoconf automake git
elif command -v dnf &>/dev/null; then
    sudo dnf install -y gcc make ncurses-devel autoconf automake git
elif command -v yum &>/dev/null; then
    sudo yum install -y gcc make ncurses-devel autoconf automake git
fi && \
if command -v apt-get &>/dev/null; then sudo apt remove --purge -y htop 2>/dev/null || true; \
else sudo dnf remove -y htop 2>/dev/null || sudo yum remove -y htop 2>/dev/null || true; fi && \
    TEMP_DIR=$(mktemp -d) && cd "$TEMP_DIR" && \
    git clone https://github.com/htop-dev/htop.git && cd htop && \
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1)) && \
    git checkout "$LATEST_TAG" && ./autogen.sh && ./configure && make && sudo make install && \
    cd .. && rm -rf "$TEMP_DIR"
```

Check your htop version with:

```bash
htop -V
```
