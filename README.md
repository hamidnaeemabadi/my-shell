# My bashrc and vimrc
## Add to your system:
```bash
# Backup .bashrc and add new one
cp ~/.bashrc ~/.bashrc.original
cp ~/.inputrc ~/.inputrc.original
curl -sL -o ~/.bashrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/bashrc
curl -sL -o ~/.inputrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/inputrc

# Backup .vimrc and add new one
cp ~/.vimrc ~/.vimrc.original
curl -sL -o ~/.vimrc https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/vimrc

# Backup .tmux.conf and add new one
cp ~/.tmux.conf ~/.tmux.conf.original
curl -sL -o ~/.tmux.conf https://raw.githubusercontent.com/hamidnaeemabadi/my-shell/main/tmux.conf
```
