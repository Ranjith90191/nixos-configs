{ config, pkgs, lib, ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      background-image = "${config.home.homeDirectory}/Downloads/wall1.png";
      background-image-opacity = 0.5;
      background-image-fit = "cover";
      background-image-position = "center";
      background-image-repeat = false;

      background-opacity = 0.1;
      background-blur = 10;

      keybind = [
        "ctrl+t=new_tab"
      ];

      window-decoration = false;
      confirm-close-surface = false;

      custom-shader = "${config.xdg.configHome}/ghostty/shaders/galaxy.glsl";
      custom-shader-animation = true;
    };
  };

  xdg.configFile."ghostty/shaders/galaxy.glsl".source = ./shaders/galaxy.glsl;
}
