# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

#Use zoxide instead of cd 
alias cd='z'

#Use c to clear
alias c='clear'

#Use n for nvim
alias n='nvim'

#use y for yazi
alias y='yazi'

#Use for rm-improved
alias rm='rip'

#Use for xcp
alias cp='xcp'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# =========================================================
# Editor
# =========================================================

alias vim='nvim'

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# =========================================================
# Video
# =========================================================

alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'

# Use file name to open file with nvim :

# 1. Handle pressing Enter on a file
command_not_found_handler() {
    # If the typed word is a valid file, open it in nvim
    if [[ -f "$1" ]]; then
        nvim "$1"
    else
        # Otherwise, throw the standard error
        echo "zsh: command not found: $1" >&2
        return 127
    fi
}


# 1. Force Zsh to trigger completion even if the line is completely empty
zstyle ':completion:*' insert-tab false

# 2. Enable the interactive visual menu
zstyle ':completion:*' menu select

# 3. Create a safe, native completer function
_empty_buffer_completer() {
  # If the command line has absolutely nothing typed in it...
  if [[ -z "$BUFFER" ]]; then
    # Safely invoke the standard file completer
    _files
    return 0
  fi
  
  # Otherwise, tell Zsh to continue with its normal behavior (commands, etc)
  return 1
}

# 4. Inject our custom behavior into Zsh's default completion chain
zstyle ':completion:*' completer _empty_buffer_completer _complete _ignored
