# my-shell — zsh theme matching bashrc my_prompt structure/colors
# ┌──[user@host]-[path]-[HH:MM:SS] rc:N (branch) [⏱ Ns]
# └─$

autoload -Uz add-zsh-hook

_my_shell_git_branch() {
  local b
  b="$(git -C . rev-parse --abbrev-ref HEAD 2>/dev/null)" || return 0
  [[ -n "$b" ]] && print -rn -- " %B%F{green}(${b})%f%b"
}

# Command elapsed time (same idea as bash DEBUG trap + PROMPT_COMMAND)
typeset -g _MY_SHELL_CMD_START=
typeset -g _MY_SHELL_ELAPSED=

_my_shell_preexec() {
  _MY_SHELL_CMD_START=$SECONDS
}

_my_shell_precmd() {
  _MY_SHELL_ELAPSED=
  if [[ -n "${_MY_SHELL_CMD_START}" ]]; then
    local e=$(( SECONDS - _MY_SHELL_CMD_START ))
    if (( e >= 1 )); then
      _MY_SHELL_ELAPSED=" %B%F{yellow}[⏱ ${e}s]%f%b"
    fi
  fi
  _MY_SHELL_CMD_START=
}

add-zsh-hook preexec _my_shell_preexec
add-zsh-hook precmd _my_shell_precmd

# Line 1: cyan frame + user@host + path + magenta time + rc + jobs + green git + yellow timer
# Line 2: cyan └─ + blue $ (red # if root)
PROMPT=$'%B%F{cyan}┌──[%f%b%(!.%B%F{red}%n%F{cyan}@%M%f%b.%B%F{cyan}%n@%M%f%b)%B%F{cyan}]%f%b-%B%F{cyan}[%~]%f%b-%B%F{magenta}[%*]%f%b%(1j. jobs:%j.) rc:%?$(_my_shell_git_branch)${_MY_SHELL_ELAPSED}'$'\n''%B%F{cyan}└─%f%b%(!.%B%F{red}#%f%b.%B%F{blue}$%f%b) '

# kube-ps1 (if plugin loaded) stays on RPROMPT — set in zshrc
RPROMPT="${RPROMPT:-}"
