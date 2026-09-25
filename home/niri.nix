{ config, pkgs, lib, ... }:
{
  xdg.configFile = {
    "niri/config.kdl".source = ./niri/config.kdl;

    # Hand-written by you, not touched by DMS — safe to manage with Nix.
    "niri/dms/binds.kdl".source   = ./niri/dms/binds.kdl;
    "niri/dms/outputs.kdl".source = ./niri/dms/outputs.kdl;
    "niri/dms/cursor.kdl".source  = ./niri/dms/cursor.kdl;

    # colors.kdl, layout.kdl, alttab.kdl, input.kdl are intentionally NOT
    # managed here — DMS writes these itself when you change settings
    # through its own UI. config.kdl includes them as `optional=true`,
    # so niri starts fine even before DMS has generated them.
  };
}
