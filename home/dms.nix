{ config, pkgs, lib, ... }:
{
  programs.dank-material-shell = {
    enable = true;

    niri = {
      enableKeybinds = false;  # you already hand-wrote dms/binds.kdl yourself
      enableSpawn = true;      # DMS auto-starts with your niri session — flag if wrong
      includes.enable = false; # keep full control of config.kdl ourselves
    };
  };

  # --- Seed-once: copied in on first install only, then left alone so ---
  # --- DMS's own UI can freely edit them without a "read-only" fight.  ---
  home.activation.dmsSeedState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DMS_DIR="$HOME/.config/DankMaterialShell"
    $DRY_RUN_CMD mkdir -p "$DMS_DIR/themes/amoledBlack"

    if [ ! -e "$DMS_DIR/settings.json" ]; then
      $DRY_RUN_CMD cp ${./dms/settings.json} "$DMS_DIR/settings.json"
      $DRY_RUN_CMD chmod u+w "$DMS_DIR/settings.json"
    fi

    if [ ! -e "$DMS_DIR/plugins.lock.json" ]; then
      $DRY_RUN_CMD cp ${./dms/plugins.lock.json} "$DMS_DIR/plugins.lock.json"
      $DRY_RUN_CMD chmod u+w "$DMS_DIR/plugins.lock.json"
    fi

    if [ ! -e "$DMS_DIR/firefox.css" ]; then
      $DRY_RUN_CMD cp ${./dms/firefox.css} "$DMS_DIR/firefox.css"
      $DRY_RUN_CMD chmod u+w "$DMS_DIR/firefox.css"
    fi

    if [ ! -e "$DMS_DIR/themes/amoledBlack/theme.json" ]; then
      $DRY_RUN_CMD cp ${./dms/themes/amoledBlack/theme.json} "$DMS_DIR/themes/amoledBlack/theme.json"
      $DRY_RUN_CMD chmod u+w "$DMS_DIR/themes/amoledBlack/theme.json"
    fi
  '';
}
