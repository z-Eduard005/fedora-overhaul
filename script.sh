#!/bin/bash
set -uo pipefail
export LANG=C
export LC_ALL=C

GITHUB_REPO="https://github.com/z-Eduard005/fedora-install.git"
MC_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/fedora-mc-installer/main/mc-installer.sh)"'
OBS_HOTKEYS_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-obs-hotkeys/main/install.sh)"'
VICINAE_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-vicinae-installer/main/install.sh)"'
OMZ_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
YTM_DOWNLOAD_URL="https://api.github.com/repos/pear-devs/pear-desktop/releases/latest"
WIN_FONTS_PKG="https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm"
EXT_CLI="$HOME/.local/bin/gnome-extensions-cli"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
WALLPAPER_FILENAMES=(windows.jpg macos.png linux.jpg)
DNF_CONF="/etc/dnf/dnf.conf"
ADWAITA_ICONS_DIR="/usr/share/icons/Adwaita"
ADWAITA_ACTIONS_ICONS_DIR="$ADWAITA_ICONS_DIR/scalable/actions"
PROJECT_DIR="$HOME/Programs/fedora-post-install"
LIBREOFFICE_USER_DIR="$HOME/.config/libreoffice/4/user"
DTP_CONF_PATH="/org/gnome/shell/extensions/dash-to-panel/"
COMPLETE_SOUND_FILE="/usr/share/sounds/freedesktop/stereo/complete.oga"
STEAMAPPS_DIR="$HOME/.steam/steam/steamapps"
BOOKMARKS_FILE="$HOME/.config/gtk-3.0/bookmarks"
SCX_LOADER_CONF="/etc/scx_loader.toml"
KERNEL_POSTINST_DIR="/etc/kernel/postinst.d"
NEWEST_CACHY_KERNEL="\$(ls /boot | grep 'vmlinuz.*cachy' | sort -V | tail -1)"
STATE_FILE="$PROJECT_DIR/state"
RPM_FUSION_PKGS=(
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
)
REMOVE_PKGS=(gnome-tour baobab malcontent-control yelp)
MEDIA_CODEC_PKGS=(x264 obs-studio-plugin-x264)
ALLOWERASING_DNF_PKGS=(power-profiles-daemon)
DNF_PKGS=(
  "fastfetch"
  "python3-pip"
  "zsh"
  "gnome-tweaks"
  "curl"
  "cabextract"
  "xorg-x11-font-utils"
  "fontconfig"
  "steam|com.valvesoftware.Steam"
)
FLATHUB_PKGS=(
  "com.mattjakeman.ExtensionManager|gnome-extensions-manager"
  "com.usebottles.bottles|bottles"
)
FLATPAK_PKGS=("com.github.neithern.g4music|g4music")
NVIDIA_DRIVER_PKGS=(akmod-nvidia xorg-x11-drv-nvidia-cuda kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig egl-wayland)
INTEL_DRIVER_PKGS=(intel-media-driver)
AMD_DRIVER_SWAP_PKG=(mesa-va-drivers mesa-va-drivers-freeworld)
CACHY_COPRS=("bieszczaders/kernel-cachyos" "bieszczaders/kernel-cachyos-addons")
CACHY_PKGS=(kernel-cachyos kernel-cachyos-devel-matched)
ALLOWERASING_CACHY_PKGS=(cachyos-settings scx-scheds-git scx-tools-git)
TEMPLATE_FILENAMES=("Text_Document.txt" "Word_Document.docx" "Excel_Document.xlsx")

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }

throw_err() {
  echo -e "$(err "$1\nTry one more time...")"
  pw-play "$COMPLETE_SOUND_FILE"
  zenity --info \
  --title="Error happend:" \
  --text="$1" \
  --width=960 --height=540
  exit 1
}

ask_confirm() {
  zenity --question \
  --title="Confirmation" \
  --width=400 \
  --height=100 \
  --ok-label="Yes" \
  --cancel-label="No" \
  --text="$1"
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

set_scx_loader_option() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}[[:space:]]*=" "$SCX_LOADER_CONF"; then
    sudo sed -i "s|^${key}[[:space:]]*=.*|${key} = \"${value}\"|" "$SCX_LOADER_CONF"
  else
    sudo sed -i "1i${key} = \"${value}\"" "$SCX_LOADER_CONF"
  fi
}

is_gpu() { lspci | grep -Ei 'vga|3d|display' | grep -qi "$1"; }

log_step() {
  echo "$(info "$step")"
}

save_step() {
  echo "${step#*]: }" >> "$STATE_FILE"
}

is_step_done() {
  grep -qxF "${step#*]: }" "$STATE_FILE"
}

run_the_step() {
  is_step_done && {
    echo "$(info "$(echo "$step" | sed 's/]:.*$/]:/') skipped")"
    return 1
  }
  log_step
}

ext_cli_disable() {
  $EXT_CLI disable "$@"; $EXT_CLI update "$@"
}

[ "$EUID" -eq 0 ] && { echo "$(err 'Do not run this script with "sudo"!')" >&2; exit 1; }

sudo -v || exit 1
while true; do
  sudo -n true
  sleep 240
  kill -0 "$$" || exit
done 2>/dev/null &

step="[0|14]: Downloading the program data"
run_the_step && {
  rm -rf "$PROJECT_DIR"
  git clone --depth=1 "$GITHUB_REPO" "$PROJECT_DIR" || throw_err "Error while downloading the program data"
  rm -rf "$PROJECT_DIR/.git/"
  sudo mkdir -p "$KERNEL_POSTINST_DIR" "$WALLPAPERS_DIR" "$ADWAITA_ACTIONS_ICONS_DIR" "$LIBREOFFICE_USER_DIR"
} && save_step

step="[1|14]: Configuring system package manager"; log_step
set_dnf_conf_option "max_parallel_downloads" "15"
set_dnf_conf_option "fastestmirror" "True"
set_dnf_conf_option "installonly_limit" "2"

step="[2|14]: Updating the system"; log_step
sudo dnf upgrade --refresh -y --skip-unavailable && sudo flatpak update || {
  sudo dnf install -y tor
  sudo systemctl start tor
  sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
  sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
}
sudo fwupdmgr refresh --force >/dev/null 2>&1
sudo fwupdmgr update -y >/dev/null 2>&1

step="[3|14]: Enabling the RPM Fusion repository (for more packages)"
run_the_step && {
  sudo dnf install -y "${RPM_FUSION_PKGS[@]}" || throw_err "RPM Fusion enabling error"
} && save_step

step="[4|14]: Installing essential drivers and codecs"
run_the_step && {
  (
    set -e
    sudo dnf install -y "${MEDIA_CODEC_PKGS[@]}" --allowerasing
    if is_gpu "amd"; then
      sudo dnf swap -y "${AMD_DRIVER_SWAP_PKG[@]}"
    fi
    if is_gpu "intel"; then
      sudo dnf install -y "${INTEL_DRIVER_PKGS[@]}"
    fi
    if is_gpu "nvidia"; then
      sudo dnf install -y "${NVIDIA_DRIVER_PKGS[@]}"
    fi
  ) || throw_err "Error while installing essential drivers and codecs"
} && save_step

step="[5|14]: Installing cachyos kernel (for better performance)"
run_the_step && {
  (
    set -e
    for copr in "${CACHY_COPRS[@]}"; do
      sudo dnf copr enable -y "$copr"
    done
    sudo dnf install -y "${CACHY_PKGS[@]}"

    sudo grubby --set-default="/boot/$(eval "$NEWEST_CACHY_KERNEL")"
    sudo tee "$KERNEL_POSTINST_DIR/99-default" > /dev/null << EOF
#!/bin/sh
set -e
grubby --set-default="/boot/${NEWEST_CACHY_KERNEL}"
EOF
    sudo chown root:root "$KERNEL_POSTINST_DIR/99-default"
    sudo chmod u+rx "$KERNEL_POSTINST_DIR/99-default"

    sudo dnf install -y "${ALLOWERASING_CACHY_PKGS[@]}" --allowerasing
    sudo dracut -f
    sudo scxctl start --sched lavd --mode gaming || sudo scxctl switch --sched lavd --mode gaming
    set_scx_loader_option "default_sched" "scx_lavd"
    set_scx_loader_option "default_mode" "Gaming"
  ) || throw_err "Error while installing cachyos kernel"
} && save_step

step="[6|14]: Installing essential programs"
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
          if grep -qxF "$name" <<< "${installed[$against_key]}"; then
            conflict_key="$against_key"
            conflict_name="$name"
            break 2
          fi
        done
      done

      add=true
      if [[ -n "$conflict_key" ]]; then
        echo "$(warn "'$conflict_name' already installed as $conflict_key, but it is recommended to use $install_key version.")"
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
    sudo dnf install -y "${ALLOWERASING_DNF_PKGS[@]}" --allowerasing
    [[ ${#final_rpm[@]} -gt 0 ]] && sudo dnf install -y "${final_rpm[@]}"
    [[ ${#final_flathub[@]} -gt 0 ]] && sudo flatpak install -y flathub "${final_flathub[@]}"
    [[ ${#final_fedora[@]} -gt 0 ]] && sudo flatpak install -y fedora "${final_fedora[@]}"
    pip3 install "$(basename $EXT_CLI)"
    [ -d "$HOME/.oh-my-zsh" ] || eval "$OMZ_INSTALLER"
    sudo rpm --nodigest -i "$WIN_FONTS_PKG"
  ) || throw_err "Error while installing essential programs"
} && save_step

step="[7|14]: Removing unnecessary programs"
run_the_step && {
  sudo dnf remove -y "${REMOVE_PKGS[@]}" || throw_err "Error while removing unnecessary programs"
} && save_step

step="[8|14]: Make the system start faster"
run_the_step && {
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg || throw_err "Error while generating grub config"
} && save_step

step="[9|14]: Tweaking terminal"
run_the_step && {
  if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
    echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
  fi
  if grep -q ' . /etc/bashrc' "$HOME/.bashrc"; then
    sed -i 's| . /etc/bashrc|#. /etc/bashrc|' "$HOME/.bashrc"
  fi
  [ "$SHELL" != "$(which zsh)" ] && chsh -s "$(which zsh)"
} && save_step

step="[10|14]: Changing default music app"
run_the_step && {
  flatpak list --app | grep -q "com.github.neithern.g4music" && xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg || echo "$(warn "Failed to set default music app")"
} && save_step

step="[11|14]: Tweaking system settings"
run_the_step && {
  powerprofilesctl set performance >/dev/null 2>&1
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
  gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'
  gsettings set org.gnome.nautilus.list-view default-zoom-level 'medium'
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
  gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
  gsettings set org.gnome.desktop.interface cursor-theme "macOS"

  cp "$PROJECT_DIR/data/registrymodifications.xcu" "$LIBREOFFICE_USER_DIR/registrymodifications.xcu"
  for f in "${TEMPLATE_FILENAMES[@]}"; do
    cp "$PROJECT_DIR/data/$f" "$HOME/Templates/$f"
  done
  sed -i "1s|^|file://$STEAMAPPS_DIR Steamapps\n|" "$BOOKMARKS_FILE"
  sed -i "1s|^|file://$WALLPAPERS_DIR Wallpapers\n|" "$BOOKMARKS_FILE"
  nautilus -q >/dev/null 2>&1
} && save_step

step="[12|14]: Installing essential gnome extensions"
run_the_step && {
  $EXT_CLI install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com || throw_err "Error while installing gnome extensions"
  ext_cli_disable background-logo@fedorahosted.org Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com || echo "$(warn "Some extensions are not disabled, so you might see some visual issues, disable them, if you need, in Extensions Manager app")"
} && save_step

step="[13|14]: Setting up look of your desktop"; log_step
for f in "${WALLPAPER_FILENAMES[@]}"; do
  cp "$PROJECT_DIR/data/$f" "$WALLPAPERS_DIR/$f"
done

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
      step="Pre-configure dash-to-panel.conf"
      ! is_step_done && dconf load "$DTP_CONF_PATH" < "$PROJECT_DIR/data/dash-to-panel.conf" && save_step
      $EXT_CLI enable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
      ext_cli_disable dash-to-dock@micxgx.gmail.com hidetopbar@mathieu.bidon.ca
    ) || echo "$(warn "Failed to set 'windows' style. Try again")"
    ;;
  "macos")
    WALLPAPER_NAME="${WALLPAPER_FILENAMES[1]}"
    (
      set -e
      $EXT_CLI install dash-to-dock@micxgx.gmail.com
      $EXT_CLI enable dash-to-dock@micxgx.gmail.com
      ext_cli_disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    ) || echo "$(warn "Failed to set 'macos' style. Try again")"
    ;;
  "linux")
    WALLPAPER_NAME="${WALLPAPER_FILENAMES[2]}"
    (
      set -e
      ext_cli_disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com
    ) || echo "$(warn "Failed to set 'linux' style. Try again")"
    ;;
esac

[ -z "$SELECTED_LOOK" ] || {
  WALLPAPER="file://$WALLPAPERS_DIR/$WALLPAPER_NAME"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER"
}

sudo cp "$PROJECT_DIR/data/view-app-grid-symbolic.svg" "$ADWAITA_ACTIONS_ICONS_DIR/view-app-grid-symbolic.svg"
sudo gtk-update-icon-cache "$ADWAITA_ICONS_DIR"
$EXT_CLI update >/dev/null 2>&1

step="[14|14]: Installing selected programs"; log_step
(
  set -e
  if selected "color-picker"; then
    $EXT_CLI install color-picker@tuberry
    $EXT_CLI update color-picker@tuberry
    $EXT_CLI enable color-picker@tuberry
  fi
  if selected "rounded-corners"; then
    $EXT_CLI install rounded-window-corners@fxgn
    $EXT_CLI update rounded-window-corners@fxgn
    $EXT_CLI enable rounded-window-corners@fxgn
  fi
  if selected "hidetopbar"; then
    $EXT_CLI install hidetopbar@mathieu.bidon.ca
    $EXT_CLI update hidetopbar@mathieu.bidon.ca
    $EXT_CLI enable hidetopbar@mathieu.bidon.ca
  fi
  if selected "vitals"; then
    $EXT_CLI install Vitals@CoreCoding.com
    $EXT_CLI update Vitals@CoreCoding.com
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
