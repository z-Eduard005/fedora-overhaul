# Post install instructions

## Necessary
1. Update your system with the command: `sudo dnf upgrade`
  1.1. if you see an error about "libopen264", try this fix: https://github.com/cisco/openh264/issues/3886#issuecomment-3163814373
  1.2. reboot
2. Enable rpm fusion repository (for more packages):
  2.1. download and install RPM Fusion from link - "RPM Fusion free for Fedora <your_verion>" on this page https://rpmfusion.org/Configuration
  2.2. install famous x264 codec: `sudo dnf in x264 obs-studio-plugin-x264 --allowerasing`
3. Make package manager faster and kernel taking less size:
  3.1. Paste the lines (with <ctrl+shift+v>) under "[main]" section of this file - `sudo nano /etc/dnf/dnf.conf`:
  ```
  max_parallel_downloads=20
  fastestmirror=True
  installonly_limit=2
  ```
  3.2. Save and exit with <ctrl+s> -> <ctrl+x>

## Must-have programs
1. GNOME tweaks (rpm) - **`programs/gnome-tweaks.md`**
2. Extension Manager (flathub) - **`programs/extension-manager.md`**
5. Bottles (flathub) - **`programs/bottles.md`**
6. Steam (rpm) - **`programs/steam.md`**
4. Easy Effects (flatpak) - simple audio 
7. qBittorrent (flatpak) - torrent manager
3. LACT (flathub) - manage your amd external video card

## Recommended/Optional
1. Vicinae (best app launcher): **`programs/vicinae.md`**
1. Zen Browser (best browser)
2. Youtube Music (best Youtube Music app): https://github.com/pear-devs/pear-desktop/releases
3. Minecraft (without license): https://github.com/z-Eduard005/fedora-mc-installer
4. Kitty (best terminal): **`programs/kitty.md`**
5. terminal utils:
  5.1. zsh: `sudo dnf in zsh && chsh -s $(which zsh)`
  5.2. oh-my-zsh: https://ohmyz.sh/#install
6. Pinta (simple paint alternitive)