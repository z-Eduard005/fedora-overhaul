#!/bin/bash
EXT_CLI="$HOME/.local/bin/gnome-extensions-cli"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
RAW_GITHUB="https://raw.githubusercontent.com/z-Eduard005/fedora-install/main"
WALLPAPERS_URL="$RAW_GITHUB/wallpapers"
DNF_CONF="/etc/dnf/dnf.conf"
MC_INSTALL_CMD='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/fedora-mc-installer/main/mc-installer.sh)"'
AUTOSTART_DIR="$HOME/.config/autostart"
VICINAE_DESKTOP_DIR="/usr/local/share/applications"

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }

ask_confirm() {
  read -rp "$(warn "$1 [y/N]: ")" proceed
  if [[ "$proceed" == [yY] ]]; then
    return 0
  else
    return 1
  fi
}

echo "$(info "[1|13]: Updating the system")"
sudo dnf upgrade -y --skip-unavailable && sudo flatpak update || {
  sudo dnf install -y tor
  sudo systemctl start tor
  sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
  sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
}

echo "$(info "[2|13]: Enable the RPM Fusion repository (for more packages)")"
if ! rpm -qa | grep -q rpmfusion-free-release; then
  sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
fi

echo "$(info "[3|13]: Installing essential codecs")"
sudo dnf install -y x264 obs-studio-plugin-x264 --allowerasing

echo "$(info "[4|13]: Make the package manager faster")"
if ! grep -qxF 'max_parallel_downloads=20' "$DNF_CONF"; then
  echo 'max_parallel_downloads=20' | sudo tee -a "$DNF_CONF" >/dev/null
fi
if ! grep -qxF 'fastestmirror=True' "$DNF_CONF"; then
  echo 'fastestmirror=True' | sudo tee -a "$DNF_CONF" >/dev/null
fi
if ! grep -qxF 'installonly_limit=2' "$DNF_CONF"; then
  echo 'installonly_limit=2' | sudo tee -a "$DNF_CONF" >/dev/null
fi

echo "$(info "[5|13]: Make the system start faster")"
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo "$(info "[6|13]: Installing Terminal utilities")"
sudo dnf install -y pip3 zsh
pip3 install gnome-extensions-cli
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
  echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
fi
if grep -q ' . /etc/bashrc' "$HOME/.bashrc"; then
  sed -i 's| . /etc/bashrc|#. /etc/bashrc|' "$HOME/.bashrc"
fi

echo "$(info "[7|13]: Changing default music app")"
sudo flatpak install -y fedora com.github.neithern.g4music
xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg

echo "$(info "[8|13]: Installing essential programs")"
sudo dnf install -y gnome-tweaks steam
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager com.usebottles.bottles

echo "$(info "[9|13]: Removing unnecessary programs")"
sudo dnf remove -y gnome-tour baobab malcontent-control yelp

echo "$(info "[10|13]: Tweaking system settings a bit")"
powerprofilesctl set performance
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.shell.app-switcher current-workspace-only true
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
gsettings set org.gnome.desktop.input-sources per-window true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Shift><Control><Alt>space']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>w']"
if ! gsettings get org.gnome.desktop.input-sources xkb-options | grep -q "grp:caps_toggle"; then
  if ask_confirm "Do you want to set keyboard layout change to CapsLock?"; then
    gsettings set org.gnome.desktop.input-sources xkb-options "['grp:caps_toggle','lv3:ralt_switch']"
  fi
fi

echo "$(info "[11|13]: Installing essential gnome extensions")"
$EXT_CLI disable background-logo@fedorahosted.org
$EXT_CLI install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection
$EXT_CLI install Vitals@CoreCoding.com && $EXT_CLI disable Vitals@CoreCoding.com
$EXT_CLI install dash-to-panel@jderose9.github.com && $EXT_CLI disable dash-to-panel@jderose9.github.com
$EXT_CLI install dash-to-dock@micxgx.gmail.com && $EXT_CLI disable dash-to-dock@micxgx.gmail.com
$EXT_CLI install gtk4-ding@smedius.gitlab.com && $EXT_CLI disable gtk4-ding@smedius.gitlab.com

echo "$(info "[12|13]: Choose look of your desktop")"
looks=("macos" "windows" "nothing")
PS3='(1 - macos, 2 - windows, 3 - do nothing): '
select SELECTED_LOOK in "${looks[@]}"; do
  if [[ -n "$SELECTED_LOOK" ]]; then
    break
  fi
done

case "$SELECTED_LOOK" in
  "windows")
    WALLPAPER_NAME="windows.jpg"
    
    curl -fsSL "$RAW_GITHUB/dash-to-panel.conf" | dconf load /org/gnome/shell/extensions/dash-to-panel/
    $EXT_CLI enable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    $EXT_CLI disable dash-to-dock@micxgx.gmail.com
    ;;
  "macos")
    WALLPAPER_NAME="macos.jpg"
    $EXT_CLI enable dash-to-dock@micxgx.gmail.com
    $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    ;;
  *)
    WALLPAPER_NAME="linux.png"
    $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com
    ;;
esac

mkdir -p "$WALLPAPERS_DIR"
curl -fsSL "$WALLPAPERS_URL/$WALLPAPER_NAME" -o "$WALLPAPERS_DIR/$WALLPAPER_NAME"

WALLPAPER="file://$WALLPAPERS_DIR/$WALLPAPER_NAME"
gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER"

gsettings set org.gnome.shell favorite-apps "['org.gnome.Ptyxis.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.SystemMonitor.desktop', 'org.mozilla.firefox.desktop', 'steam.desktop']"

echo "$(info "[13|13]: Install recommended programs")"
if ! $EXT_CLI list | grep -q color-picker@tuberry; then
  if ask_confirm "Do you want to install Color Picker Extension?"; then
    $EXT_CLI install color-picker@tuberry
  fi
fi
if ! $EXT_CLI list | grep -q rounded-window-corners@fxgn; then
  if ask_confirm "Do you want to install Rounded Window Corners (FOR ALL APPS) Extension?"; then
    $EXT_CLI install rounded-window-corners@fxgn
  fi
fi
if ! $EXT_CLI list | grep -q hidetopbar@mathieu.bidon.ca; then
  if ask_confirm "Do you want to install Hide Top Bar Extension?"; then
    $EXT_CLI install hidetopbar@mathieu.bidon.ca
  fi
fi
if ask_confirm "Do you want to install Minecraft (FREE VERSION)"; then
  if ! eval "$MC_INSTALL_CMD" >/dev/null 2>&1; then
    echo "$(err "Minecraft installation failed. Try later by running this script:")"
    echo "$(info "$MC_INSTALL_CMD")"
  fi
fi
if ask_confirm "Do you want to install YouTube Music App (best client for ytm)"; then
  curl -s https://api.github.com/repos/pear-devs/pear-desktop/releases/latest |
  grep browser_download_url |
  grep x86_64.rpm |
  cut -d '"' -f 4 |
  xargs curl -L -o "$HOME/Downloads/pear-desktop.rpm"
  sudo dnf install -y "$HOME/Downloads/pear-desktop.rpm"
fi
if ask_confirm "Do you want to install Vicinae (app launcher, clipboard manager and many more)"; then
  $EXT_CLI install vicinae@dagimg-dot
  curl -fsSL https://vicinae.com/install.sh | bash && systemctl --user enable vicinae --now
  mkdir -p "$AUTOSTART_DIR"
  cp "$VICINAE_DESKTOP_DIR/vicinae.desktop" "$AUTOSTART_DIR"

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ name 'Vicinae Toggle'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ command 'vicinae toggle'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ binding '<Alt>space'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ name 'Vicinae Clipboard'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ command 'vicinae deeplink vicinae://launch/clipboard/history'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ binding '<Alt>v'

  echo "$(success "Vicinae installed. To use it, just press Alt+Space")"
  echo "$(success "And for using clipboard manager press Alt+V")"
fi

echo "$(success "Your Fedora installation is ready to use! Have fun :)")"
echo "$(success "You can install any app in default Software App or from browser using .rpm .AppImage or snap files format")"
if ask_confirm "Your system needs to reboot after all changes to take effect. Do you want to reboot now?"; then
  systemctl reboot
fi
