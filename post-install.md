# Post install instructions

## Necessary
1. Update your system with the command: `sudo dnf upgrade`  
  1.1. If you see an error about "libopen264", try this fix: https://github.com/cisco/openh264/issues/3886#issuecomment-3163814373  
  1.2. Reboot.  
2. Enable the RPM Fusion repository (for more packages):  
  2.1. Download and install RPM Fusion from the link — "RPM Fusion free for Fedora <your_version>" on this page: https://rpmfusion.org/Configuration  
  2.2. Install the popular x264 codec: `sudo dnf in x264 obs-studio-plugin-x264 --allowerasing`
3. Make the package manager faster and reduce kernel size:  
  3.1. Paste the lines (with <ctrl+shift+v>) under the "[main]" section of this file — `sudo nano /etc/dnf/dnf.conf`:
    ```
    max_parallel_downloads=20
    fastestmirror=True
    installonly_limit=2
    ```
    3.2. Save and exit with <ctrl+s> → <ctrl+x>.

## Must-have programs
1. **GNOME tweaks** (rpm) - **`programs/gnome-tweaks.md`**
2. **Extension Manager** (flathub) - **`programs/extension-manager.md`**
5. **Bottles** (flathub) - **`programs/bottles.md`**
6. **Steam** (rpm) - **`programs/steam.md`**
4. **Easy Effects** (flatpak) - simple audio options
7. **qBittorrent** (flatpak) - torrent manager
3. **LACT** (flathub) - manage your AMD external video card

## Recommended/Optional
1. **Vicinae** (best app launcher): **`programs/vicinae.md`**
1. **Zen Browser** (best browser)
2. **YouTube Music** (best YouTube Music app): https://github.com/pear-devs/pear-desktop/releases
3. **Minecraft** (without a license): https://github.com/z-Eduard005/fedora-mc-installer
4. **Kitty** (best terminal): **`programs/kitty.md`**
6. **Pinta** (simple Paint alternative)