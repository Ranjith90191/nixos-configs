{ config, pkgs, username, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "mymachine";
  time.timeZone = "Asia/Kolkata";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "input" "networkmanager" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  programs.niri.enable = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  services.power-profiles-daemon.enable = true;
  zramSwap.enable = true;

  services.greetd.enable = true;
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;    # RTX 2050 is Ampere (GA107) — open kernel modules supported
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      # Confirmed via lspci: Intel UHD @ 00:02.0, RTX 2050 @ 01:00.0
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  system.stateVersion = "24.11";
}
