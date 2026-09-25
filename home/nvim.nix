{ config, pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    # EDITOR/VISUAL already set in zsh.nix's envExtra — not duplicating here.
    defaultEditor = false;
  };

  home.packages = with pkgs; [
    git   # lazy.nvim bootstraps itself via `git clone` on first launch
    gcc   # nvim-treesitter compiles parsers at runtime by shelling out to `cc`
  ];

  xdg.configFile."nvim/init.lua".source        = ./nvim/init.lua;
  xdg.configFile."nvim/lazy-lock.json".source  = ./nvim/lazy-lock.json;
}
