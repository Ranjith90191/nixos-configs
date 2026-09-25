# THIS FILE IS A PLACEHOLDER.
# Real hardware-configuration.nix is generated on the target machine by:
#   sudo nixos-generate-config --root /mnt
# Overwrite this file with that output before running nixos-install.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ ];
  boot.kernelModules = [ ];
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
}
