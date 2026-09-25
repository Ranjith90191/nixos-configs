# NixOS Installation Guide — Replace Arch, Keep Windows

> [!IMPORTANT]
> This guide is tailored to **your exact disk layout**. Read it fully before starting.

---

## Your Disk Layout (nvme0n1)

```
Partition          Size     Type   What               Action
─────────────────────────────────────────────────────────────
/dev/nvme0n1p1     300M     vfat   Windows EFI        🔒 KEEP (don't touch)
/dev/nvme0n1p2      16M     —      Microsoft reserved 🔒 KEEP
/dev/nvme0n1p3   300.5G     ntfs   Windows C:         🔒 KEEP
/dev/nvme0n1p4    27.1G     ntfs   Windows Recovery   🔒 KEEP
/dev/nvme0n1p5       2G     vfat   Linux EFI (/boot)  ♻️  REUSE — wipe & reformat
/dev/nvme0n1p6   146.3G     ext4   Arch root (/)      💀 WIPE — becomes NixOS
/dev/nvme0n1p7     735M     swap   Linux swap         ♻️  REUSE as-is
```

> [!CAUTION]
> **Do NOT touch p1, p2, p3, p4** — those are Windows. You're only wiping **p5** (Linux EFI) and **p6** (Arch root).

---

## Before You Start

### 1. Push your config repo (do this NOW, on Arch, before rebooting)

```bash
cd ~/nixos-config
git add -A
git commit -m "finalize config before NixOS install"
git push origin main
```

### 2. Back up anything you want from Arch

Your home directory, Downloads, any files not in the repo — everything on `/dev/nvme0n1p6` will be erased.

```bash
# Example: copy important files to a USB drive
cp -r ~/Documents ~/Downloads /mnt/usb-drive/
```

### 3. Download NixOS Minimal ISO

Get it from: https://nixos.org/download/#nixos-iso — choose **Minimal ISO image (64-bit Intel/AMD)**

Flash to USB:
```bash
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
# Replace /dev/sdX with your USB drive (NOT nvme0n1!)
```

---

## Installation

### Step 1 — Boot the NixOS USB

Reboot → Enter BIOS boot menu (usually F12/F2/Esc) → Select the USB drive.

You'll land in a root shell on the NixOS live environment.

### Step 2 — Connect to WiFi

```bash
# Start the interactive WiFi tool
sudo systemctl start wpa_supplicant
nmcli device wifi list
nmcli device wifi connect "YOUR_WIFI_NAME" password "YOUR_PASSWORD"

# Verify
ping -c 3 google.com
```

### Step 3 — Format the Linux partitions

> [!WARNING]
> Double-check partition numbers! `p5` is your Linux EFI, `p6` is your Arch root.
> **Do NOT format p1** (Windows EFI).

```bash
# Wipe and reformat the Linux EFI partition
sudo mkfs.fat -F 32 /dev/nvme0n1p5

# Wipe and reformat the Arch root → NixOS root
sudo mkfs.ext4 /dev/nvme0n1p6

# Activate swap (already exists, reuse as-is)
sudo swapon /dev/nvme0n1p7
```

### Step 4 — Mount everything

```bash
# Mount NixOS root
sudo mount /dev/nvme0n1p6 /mnt

# Create boot mount point and mount Linux EFI
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p5 /mnt/boot
```

### Step 5 — Generate hardware config

```bash
sudo nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your real disk UUIDs, detected kernel modules, etc.

### Step 6 — Clone your repo

```bash
sudo nix-shell -p git --run "git clone https://github.com/Ranjith90191/nixos-configs.git /mnt/etc/nixos-config"
```

> [!NOTE]
> Using HTTPS here because SSH keys aren't set up on the live ISO. You can switch to SSH after first boot.

### Step 7 — Copy real hardware config into repo

```bash
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos-config/hosts/mymachine/hardware-configuration.nix
```

### Step 8 — Install NixOS

```bash
sudo nixos-install --flake /mnt/etc/nixos-config#mymachine
```

This will:
- Download and build your entire system (takes 15–45 min depending on network)
- Ask you to set the **root password** at the end

> [!TIP]
> If it fails on a specific package or module, read the error carefully.
> Common first-build issues:
> - DMS/dankcalendar/dsearch/helium flake not fetching → check network
> - `niri` config parse error (`recent-windows`) → edit `flake.nix` and change `niri.url` to explicitly track unstable

### Step 9 — Reboot into NixOS

```bash
sudo reboot
```

Remove the USB drive. GRUB should appear with **NixOS** and **Windows** as boot options.

---

## After First Boot

### Log in

At the DMS greeter, log in as `yhwach` (the password you set during `nixos-install` for root won't work here — you need to set your user password).

**If you can't log in** — that's because `nixos-install` only sets the root password. Switch to a TTY:

```bash
# Press Ctrl+Alt+F2 to get a TTY
# Log in as root with the password you set during install
# Then set your user password:
passwd yhwach
# Switch back to greeter: Ctrl+Alt+F1
```

### Move repo to home directory

```bash
sudo mv /etc/nixos-config ~/nixos-config
sudo chown -R yhwach:users ~/nixos-config
```

### Set up SSH keys for GitHub

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
# Copy the output → GitHub → Settings → SSH Keys → Add
```

Then switch the remote to SSH:
```bash
cd ~/nixos-config
git remote set-url origin git@github.com:Ranjith90191/nixos-configs.git
```

### Future updates workflow

```bash
cd ~/nixos-config
# Make changes...
sudo nixos-rebuild switch --flake .#mymachine
git add -A && git commit -m "description" && git push
```

---

## Troubleshooting

### GRUB doesn't show Windows

```bash
# NixOS already has os-prober enabled in your config
# Just regenerate GRUB:
sudo nixos-rebuild switch --flake ~/nixos-config#mymachine
```

If still missing, check that os-prober can see it:
```bash
sudo os-prober
# Should output something like:
# /dev/nvme0n1p1@/EFI/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi
```

### No WiFi after boot

```bash
# NetworkManager is enabled in your config — it should just work
nmcli device wifi list
nmcli device wifi connect "YOUR_WIFI_NAME" password "YOUR_PASSWORD"
```

### No sound

```bash
# PipeWire is configured — check it's running:
systemctl --user status pipewire
# Open volume control:
pavucontrol   # (you didn't install this — use: nix-shell -p pavucontrol --run pavucontrol)
```

### Nvidia not working

```bash
# Check the driver loaded:
nvidia-smi
# Test offload:
nvidia-offload glxinfo | grep "OpenGL renderer"
```

### Ghostty shows no wallpaper

Expected — `~/Downloads/wall1.png` doesn't exist yet. Copy your wallpaper there:
```bash
mkdir -p ~/Downloads
cp /path/to/your/wall1.png ~/Downloads/wall1.png
```
