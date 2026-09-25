{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # CLI essentials (aliases depend on these)
    eza
    ripgrep
    fd
    bat
    yazi
    mpv
    xcp
    rm-improved

    # Dev tools
    verilator
    verilog          # iverilog
    markdownlint-cli2
    tree-sitter
    stylua
    python3Packages.pip

    # Editors / TUI
    vim
    btop

    # System / remote
    tigervnc
    git

    # GUI apps
    thunderbird
    kdePackages.dolphin-plugins
  ];

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    # We run compinit manually below with the original custom cache path,
    # so disable home-manager's own auto-compinit.
    enableCompletion = false;

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.stateHome}/zsh/history";
      append = true;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };

    envExtra = ''
      # ---------- XDG base directories ----------
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"

      # ---------- Editor ----------
      export EDITOR="nvim"
      export VISUAL="nvim"

      # ---------- Pager ----------
      if command -v bat >/dev/null 2>&1; then
        export MANPAGER="bat -l man -p"
      elif command -v batcat >/dev/null 2>&1; then
        export MANPAGER="batcat -l man -p"
      fi

      # ---------- GPG ----------
      export GPG_TTY=$(tty)

      # ---------- Starship ----------
      export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

      # ---------- PATH ----------
      export PATH="$HOME/.local/bin:$PATH"
    '';

    # Runs BEFORE plugins load. bindings.zsh sets ZVM_* vars and defines
    # zvm_after_init(), which zsh-vi-mode calls at the end of its own init —
    # so it (and fzf.zsh, which defines the widget bindings.zsh references)
    # must be sourced before the plugin list below runs.
    initExtraBeforeCompInit = ''
      setopt HIST_FIND_NO_DUPS
      setopt AUTOCD
      setopt NOBEEP
      setopt NUMERIC_GLOB_SORT

      if [[ -f ~/.config/lf/icons ]]; then
        LF_ICONS=$(cat ~/.config/lf/icons | tr '\n' ':')
        export LF_ICONS
      fi

      autoload -Uz compinit
      compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      source "$ZDOTDIR/fzf.zsh"
      source "$ZDOTDIR/aliases.zsh"
      source "$ZDOTDIR/bindings.zsh"
    '';

    # Runs AFTER plugins load — same relative order as the original .zshrc.
    initExtra = ''
      source "$ZDOTDIR/prompt.zsh"

      export GRAVEYARD="$HOME/.local/share/graveyard"

      if [[ -f "$ZDOTDIR/local.zsh" ]]; then
        source "$ZDOTDIR/local.zsh"
      fi
    '';

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."zsh/aliases.zsh".source   = ./zsh/aliases.zsh;
  xdg.configFile."zsh/fzf.zsh".source       = ./zsh/fzf.zsh;
  xdg.configFile."zsh/bindings.zsh".source  = ./zsh/bindings.zsh;
  xdg.configFile."zsh/prompt.zsh".source    = ./zsh/prompt.zsh;
  xdg.configFile."zsh/starship.toml".source = ./zsh/starship.toml;
}
