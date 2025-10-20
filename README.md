# My Custom Shell

## Add to your system

### Backup `.bashrc` and add a new one

```bash
cp ~/.bashrc ~/.bashrc.original
cp ~/.inputrc ~/.inputrc.original
curl -sL -o ~/.bashrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/bashrc
curl -sL -o ~/.inputrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/inputrc
```

### Backup `.vimrc` and add a new one

```bash
cp ~/.vimrc ~/.vimrc.original
curl -sL -o ~/.vimrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/vimrc
```

### Backup `.tmux.conf` and add a new one

```bash
cp ~/.tmux.conf ~/.tmux.conf.original
curl -sL -o ~/.tmux.conf https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/tmux.conf
```

### Backup old htop config and add a new one

```bash
cp ~/.config/htop/htoprc ~/.config/htop/htoprc.original
curl -sL -o ~/.config/htop/htoprc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/htoprc
```

- If your htop is not the latest version, you can compile it from source (open a new shell to use the new htop):

  ```bash
  sudo apt-get -qq update && sudo apt-get install -y build-essential libncursesw5-dev autotools-dev \
      autoconf automake git && sudo apt remove --purge -y htop && \
      TEMP_DIR=$(mktemp -d) && cd "$TEMP_DIR" && \ 
      git clone https://github.com/htop-dev/htop.git && cd htop && \ 
      LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1)) && \ 
      git checkout "$LATEST_TAG" && ./autogen.sh && ./configure && make && sudo make install && \
      cd .. && rm -rf "$TEMP_DIR"
  ```

- Check your htop version with:

  ```bash
  htop -V
  ```
