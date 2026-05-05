#!/bin/bash
RAW_GITHUB="https://raw.githubusercontent.com/z-Eduard005/fedora-install/main"
MC_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/fedora-mc-installer/main/mc-installer.sh)"'
OBS_HOTKEYS_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-obs-hotkeys/main/install.sh)"'
VICINAE_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-vicinae-installer/main/install.sh)"'
OMZ_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
YTM_DOWNLOAD_URL="https://api.github.com/repos/pear-devs/pear-desktop/releases/latest"
EXT_CLI="$HOME/.local/bin/gnome-extensions-cli"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
WALLPAPERS_URL="$RAW_GITHUB/wallpapers"
WALLPAPER_FILENAMES=(windows.jpg macos.png linux.jpg)
DNF_CONF="/etc/dnf/dnf.conf"
PROJECT_DIR="$HOME/Programs/fedora-post-install"
LIBREOFFICE_USER_DIR="$HOME/.config/libreoffice/4/user"
DTP_CONF_PATH="/org/gnome/shell/extensions/dash-to-panel/"

RPM_FUSION_PKGS=(
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
)
REMOVE_PKGS=(gnome-tour baobab malcontent-control yelp)
CODEC_PKGS=(x264 obs-studio-plugin-x264)
DNF_PKGS=(
  "python3-pip"
  "zsh"
  "gnome-tweaks"
  "steam|com.valvesoftware.Steam"
)
FLATHUB_PKGS=(
  "com.mattjakeman.ExtensionManager|gnome-extensions-manager"
  "com.usebottles.bottles|bottles"
)
FLATPAK_PKGS=(
  "com.github.neithern.g4music|g4music"
)

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }

throw_err() {
  echo "$(err "$1")"
  echo "$(warn "Try one more time...")"
  zenity --info \
  --title="Error happend:" \
  --text="$1" \
  --width=960 --height=540
  exit 1
}

ask_confirm() {
  read -rp "$(warn "$1 [y/N]: ")" proceed
  [[ "$proceed" == [yY] ]]
}

set_dnf_conf_option() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$DNF_CONF"; then
    sudo sed -i "s|^${key}=.*|${key}=${value}|" "$DNF_CONF"
  else
    echo "${key}=${value}" | sudo tee -a "$DNF_CONF" >/dev/null
  fi
}

log_step() {
  echo "$(info "$step")"
}

save_step() {
  echo "$step" >> "$STATE_FILE"
}

run_the_step() {
  grep -qxF "$step" "$STATE_FILE" && {
    echo "$(info "$(echo "$step" | sed 's/]:.*$/]:/') skipped")"
    return 1
  }
  log_step
}

[ "$EUID" -eq 0 ] && { echo "$(err 'Do not run this script with "sudo"!')" >&2; exit 1; }

sudo -v || exit 1
while true; do
  sudo -n true
  sleep 240
  kill -0 "$$" || exit
done 2>/dev/null &

mkdir -p "$PROJECT_DIR"
STATE_FILE="$PROJECT_DIR/state"
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

step="[1|13]: Configuring system package manager"; log_step
set_dnf_conf_option "max_parallel_downloads" "15"
set_dnf_conf_option "fastestmirror" "True"
set_dnf_conf_option "installonly_limit" "2"

step="[2|13]: Updating the system"; log_step
sudo dnf upgrade -y --skip-unavailable && sudo flatpak update || {
  sudo dnf install -y tor
  sudo systemctl start tor
  sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
  sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
}
sudo fwupdmgr refresh >/dev/null 2>&1 && sudo fwupdmgr update >/dev/null 2>&1

step="[3|13]: Enabling the RPM Fusion repository (for more packages)"
run_the_step && {
  sudo dnf install -y "${RPM_FUSION_PKGS[@]}" || throw_err "RPM Fusion enabling error"
} && save_step

step="[4|13]: Installing essential codecs"
run_the_step && {
  sudo dnf install -y "${CODEC_PKGS[@]}" --allowerasing || throw_err "Error while installing codecs"
} && save_step

step="[5|13]: Installing essential programs"
run_the_step && {
  declare -A installed=(
    [rpm]="$(rpm -qa --qf '%{NAME}\n' 2>/dev/null)"
    [flathub]="$(flatpak list --app --columns=application,origin 2>/dev/null | awk '$2=="flathub" {print $1}')"
    [fedora]="$(flatpak list --app --columns=application,origin 2>/dev/null | awk '$2=="fedora"  {print $1}')"
  )

  declare -A remove_cmd=(
    [rpm]="sudo dnf remove -y"
    [flathub]="sudo flatpak remove -y"
    [fedora]="sudo flatpak remove -y"
  )

  declare -A pkg_map=(
    [DNF_PKGS]="rpm"
    [FLATHUB_PKGS]="flathub"
    [FLATPAK_PKGS]="fedora"
  )

  final_rpm=()
  final_flathub=()
  final_fedora=()

  for arr_name in "${!pkg_map[@]}"; do
    install_key="${pkg_map[$arr_name]}"
    declare -n pkg_arr="$arr_name"

    for entry in "${pkg_arr[@]}"; do
      IFS='|' read -ra names <<< "$entry"
      conflict_key="" conflict_name=""

      for name in "${names[@]}"; do
        for against_key in "${!installed[@]}"; do
          [[ "$against_key" == "$install_key" ]] && continue
          if grep -Fqx "$name" <<< "${installed[$against_key]}"; then
            conflict_key="$against_key"
            conflict_name="$name"
            break 2
          fi
        done
      done

      add=true
      if [[ -n "$conflict_key" ]]; then
        echo "$(warn "'$conflict_name' already installed as $conflict_key")"
        if ask_confirm "Do you want to reinstall as $install_key? (this will delete app data)"; then
          eval "${remove_cmd[$conflict_key]} '$conflict_name'" || throw_err "Failed to remove $conflict_name"
        else
          add=false
        fi
      fi

      if $add; then
        declare -n final_arr="final_${install_key}"
        final_arr+=("${entry%%|*}")
        unset -n final_arr
      fi
    done

    unset -n pkg_arr
  done

  (
    set -e
    [[ ${#final_rpm[@]} -gt 0 ]] && sudo dnf install -y "${final_rpm[@]}"
    [[ ${#final_flathub[@]} -gt 0 ]] && sudo flatpak install -y flathub "${final_flathub[@]}"
    [[ ${#final_fedora[@]} -gt 0 ]] && sudo flatpak install -y fedora "${final_fedora[@]}"
    pip3 install $(basename $EXT_CLI)
    [ -d "$HOME/.oh-my-zsh" ] || eval "$OMZ_INSTALLER"
  ) || throw_err "Error while installing essential programs"
} && save_step

step="[6|13]: Removing unnecessary programs"
run_the_step && {
  sudo dnf remove -y "${REMOVE_PKGS[@]}" || throw_err "Error while removing unnecessary programs"
} && save_step

step="[7|13]: Make the system start faster"
run_the_step && {
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg || throw_err "Error while generating grub config"
} && save_step

step="[8|13]: Tweaking terminal"
run_the_step && {
  if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
    echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
  fi
  if grep -q ' . /etc/bashrc' "$HOME/.bashrc"; then
    sed -i 's| . /etc/bashrc|#. /etc/bashrc|' "$HOME/.bashrc"
  fi
  [ "$SHELL" != "$(which zsh)" ] && chsh -s "$(which zsh)"
} && save_step

step="[9|13]: Changing default music app"
run_the_step && {
  xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg || echo "$(warn "Failed to set default music app")"
} && save_step

step="[10|13]: Tweaking system settings"
run_the_step && {
  powerprofilesctl set performance
  gsettings set org.gnome.desktop.interface enable-hot-corners false
  gsettings set org.gnome.shell.app-switcher current-workspace-only true
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
  gsettings set org.gnome.desktop.input-sources per-window true
  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
  gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
  gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Shift><Control><Alt>space']"
  gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>w']"
  gsettings set org.gnome.shell favorite-apps "['org.gnome.Ptyxis.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.SystemMonitor.desktop', 'org.mozilla.firefox.desktop', 'steam.desktop']"
  gsettings set org.gnome.desktop.input-sources xkb-options "['grp:caps_toggle','lv3:ralt_switch']"

  mkdir -p "$LIBREOFFICE_USER_DIR"
  cat > "$LIBREOFFICE_USER_DIR/registrymodifications.xcu" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Writer']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Calc']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Impress']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Draw']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="SymbolStyle" oor:op="fuse"><value>sukapura_svg</value></prop></item>
</oor:items>
EOF
} && save_step

step="[11|13]: Installing essential gnome extensions"
run_the_step && {
  $EXT_CLI install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com || throw_err "Error while installing gnome extensions"
  $EXT_CLI disable background-logo@fedorahosted.org Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com || echo "$(warn "Some extensions are not disabled, so you might see some visual issues, disable them, if you need, in Extensions Manager app")"
} && save_step

step="[12|13]: Setting up look of your desktop"; log_step
mkdir -p "$WALLPAPERS_DIR" "$PROJECT_DIR/data"
for f in "${WALLPAPER_FILENAMES[@]}"; do
  [ -f "$WALLPAPERS_DIR/$f" ] || curl -fsSL "$WALLPAPERS_URL/$f" -o "$WALLPAPERS_DIR/$f" || echo "$(warn "Wallpapers failed to install")"
done
curl -fsSL "$RAW_GITHUB/dash-to-panel.conf" -o "$PROJECT_DIR/data/dash-to-panel.conf" || throw_err 'Failed to download "dash-to-panel.conf"'

SELECTED_LOOK=$(zenity --list --radiolist \
  --title="Desktop Look" \
  --text="Choose the look of your desktop:" \
  --column="" --column="Look" \
  FALSE "macos" FALSE "windows" TRUE "linux" \
  --width=480 --height=480)

PROGRAMS=$(zenity --list --checklist \
  --title="Programs to install" \
  --text="Select programs then click OK:" \
  --column="Install" --column="ID" --column="Description" \
  --separator=" " \
  FALSE "color-picker"    "Color Picker (GNOME Extension)" \
  FALSE "rounded-corners" "Rounded Window Corners (GNOME Extension)" \
  FALSE "hidetopbar"      "Hide Top Bar (GNOME Extension)" \
  FALSE "vitals"          "Vitals - system monitor" \
  FALSE "minecraft"       "Minecraft (FREE VERSION)" \
  FALSE "youtube-music"   "YouTube Music App" \
  FALSE "vicinae"         "Vicinae - launcher & clipboard manager" \
  FALSE "obs-hotkeys"     "Fix OBS recording hotkeys (you want this if you will record with obs)" \
  --width=960 --height=540)

selected() { echo "$PROGRAMS" | grep -qw "$1"; }

case "$SELECTED_LOOK" in
  "windows")
    WALLPAPER_NAME="${WALLPAPER_FILENAMES[0]}"
    (
      set -e
      $EXT_CLI install gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
      dconf load "$DTP_CONF_PATH" < "$PROJECT_DIR/data/dash-to-panel.conf"
      $EXT_CLI enable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
      $EXT_CLI disable dash-to-dock@micxgx.gmail.com hidetopbar@mathieu.bidon.ca
    ) || echo "$(warn "Failed to set 'windows' style. Try again")"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ;;
  "macos")
    WALLPAPER_NAME="${WALLPAPER_FILENAMES[1]}"
    (
      set -e
      $EXT_CLI install dash-to-dock@micxgx.gmail.com
      $EXT_CLI enable dash-to-dock@micxgx.gmail.com
      $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    ) || echo "$(warn "Failed to set 'macos' style. Try again")"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ;;
  "linux")
    WALLPAPER_NAME="${WALLPAPER_FILENAMES[2]}"
    (
      set -e
      $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com
    ) || echo "$(warn "Failed to set 'linux' style. Try again")"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    ;;
esac

[ -z "$SELECTED_LOOK" ] || {
  WALLPAPER="file://$WALLPAPERS_DIR/$WALLPAPER_NAME"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER"
}

step="[13|13]: Installing recommended programs"; log_step
(
  set -e
  if selected "color-picker"; then
    $EXT_CLI install color-picker@tuberry
    $EXT_CLI enable color-picker@tuberry
  fi
  if selected "rounded-corners"; then
    $EXT_CLI install rounded-window-corners@fxgn
    $EXT_CLI enable rounded-window-corners@fxgn
  fi
  if selected "hidetopbar"; then
    $EXT_CLI install hidetopbar@mathieu.bidon.ca
    $EXT_CLI enable hidetopbar@mathieu.bidon.ca
  fi
  if selected "vitals"; then
    $EXT_CLI install Vitals@CoreCoding.com
    $EXT_CLI enable Vitals@CoreCoding.com
  fi
) || echo "$(warn "Some extensions failed to enable. Try again")"

if selected "minecraft"; then
  eval "$MC_INSTALLER" || echo "$(warn "Minecraft installation failed. Try later by running this program again")"
fi

if selected "youtube-music"; then
  proceed_ytm_install=true

  is_ytm_exists=0
  rpm -qa | grep -q youtube-music && is_ytm_exists=1

  [ $is_ytm_exists -eq 0 ] && {
    echo "$(warn "YouTube Music App is already installed")"
    ask_confirm "Do you want to reinstall?" || proceed_ytm_install=false
  }

  if $proceed_ytm_install; then
    ytm_release_url=$(echo "$YTM_DOWNLOAD_URL" | sed 's/api\.//; s/repos\///')
    echo "Installing YouTube Music App from \"$ytm_release_url\"..."
    (
      set -e
      [ $is_ytm_exists -eq 0 ] && sudo dnf remove -y youtube-music
      curl -s "$YTM_DOWNLOAD_URL" | grep browser_download_url | grep x86_64.rpm | cut -d '"' -f 4 | xargs curl -L -o "$HOME/Downloads/youtube-music.rpm"
      sudo dnf install -y "$HOME/Downloads/youtube-music.rpm"
    ) || echo "$(warn "Error while installing Youtube Music App. Try again")"
  fi
fi

if selected "vicinae"; then
  eval "$VICINAE_INSTALLER" || echo "$(warn "Vicinae installation failed. Try later by running this program again")"
fi

if selected "obs-hotkeys"; then
  eval "$OBS_HOTKEYS_INSTALLER" || echo "$(warn "OBS Hotkeys installation failed. Try later by running this program again")"
fi

zenity --info \
  --title="Setup Complete!" \
  --text="🎉 Your Fedora installation is ready to use! Have fun :)\n\nYou can install any app in the default Software App or from browser using .rpm (x86_64), .AppImage or .snap file formats.\n\nWhat was done:\n• Package manager optimized\n• System updated\n• RPM Fusion enabled\n• Essential codecs installed\n• Boot time reduced\n• Terminal utilities installed (zsh, oh-my-zsh)\n• Default music app changed\n• Essential programs installed\n• Unnecessary programs removed\n• System settings tweaked\n• GNOME extensions installed\n• Desktop look configured\n• Selected programs installed\n\n⚠️ Your system needs to reboot for all changes to take effect." \
  --width=960 --height=540

zenity --question \
  --title="Reboot" \
  --text="Do you want to reboot now?" \
  --ok-label="Reboot now" \
  --cancel-label="Later" \
  --width=480 --height=480 && systemctl reboot
