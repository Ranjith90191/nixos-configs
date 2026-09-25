{ config, pkgs, username, ... }:
{
  imports = [
    ./ghostty.nix
    ./niri.nix
    ./nvim.nix
    ./zsh.nix
    ./dms.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
