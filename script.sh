#!/bin/bash
set -uo pipefail
export LANG=C
export LC_ALL=C

GITHUB_REPO="https://github.com/z-Eduard005/fedora-overhaul.git"
MC_INSTALLER='/bin/bash -lc "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/linux-mc-installer/main/installer.sh)"'
OBS_HOTKEYS_INSTALLER='/bin/bash -lc "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-obs-hotkeys/main/install.sh)"'
VICINAE_INSTALLER='/bin/bash -lc "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-vicinae-installer/main/install.sh)"'
OMZ_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
YTM_DOWNLOAD_URL="https://api.github.com/repos/pear-devs/pear-desktop/releases/latest"
WIN_FONTS_PKG="https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm"
ADW_COLORS_REPO="https://github.com/dpejoh/Adwaita-colors"
TMP_ADW_COLORS_DIR="/tmp/Adwaita-colors"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
CURSORS_DIR="$HOME/.local/share/icons"
WALLPAPER_FILENAMES=(windows.jpg macos.png linux.jpg)
DNF_CONF="/etc/dnf/dnf.conf"
PROJECT_DIR="/opt/fedora-overhaul"
LIBREOFFICE_USER_DIR="$HOME/.config/libreoffice/4/user"
SERVICE_DIR="$HOME/.config/systemd/user"
STEAMAPPS_DIR="$HOME/.steam/steam/steamapps"
BOOKMARKS_FILE="$HOME/.config/gtk-3.0/bookmarks"
SCX_LOADER_CONF="/etc/scx_loader.toml"
STATE_FILE="$PROJECT_DIR/state"
RPM_FUSION_PKGS=(
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
)
REMOVE_PKGS=("decibels" "showtime" "gnome-tour" "baobab" "malcontent-control" "yelp")
MEDIA_CODEC_PKGS=("x264" "obs-studio-plugin-x264")
ALLOWERASING_DNF_PKGS=("power-profiles-daemon")
DNF_PKGS=(
  "vlc"
  "fastfetch"
  "python3-pip"
  "zsh"
  "gnome-tweaks"
  "cabextract"
  "xorg-x11-font-utils"
  "fontconfig"
  "adw-gtk3-theme"
  "ydotool"
  "steam|com.valvesoftware.Steam"
)
FLATHUB_PKGS=(
  "com.mattjakeman.ExtensionManager|gnome-extensions-manager"
  "com.usebottles.bottles|bottles"
)
FLATPAK_PKGS=("com.github.neithern.g4music|g4music")
NVIDIA_DRIVER_PKGS=("akmod-nvidia" "xorg-x11-drv-nvidia-cuda" "kernel-devel" "kernel-headers" "gcc" "make" "dkms" "acpid" "libglvnd-glx" "libglvnd-opengl" "libglvnd-devel" "pkgconfig" "egl-wayland")
INTEL_DRIVER_PKGS=("intel-media-driver")
AMD_DRIVER_SWAP_PKG=("mesa-va-drivers" "mesa-va-drivers-freeworld")
CACHY_COPRS=("bieszczaders/kernel-cachyos" "bieszczaders/kernel-cachyos-addons")
CACHY_TOOL_PKGS=("grubby" "libdnf5-plugin-actions")
CACHY_KERNEL_PKGS=("kernel-cachyos" "kernel-cachyos-devel-matched")
ALLOWERASING_CACHY_PKGS=("cachyos-settings" "scx-scheds-git" "scx-tools-git")
TEMPLATE_FILENAMES=("Text_Document.txt" "Word_Document.docx" "Excel_Document.xlsx")

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }

throw_err() {
  echo "$(err "Error: $1")"
  yad --error \
  --title="Error happened" \
  --button="OK:0" \
  --text="<span font='14'>$1</span>"
  exit 1
}

ask_confirm() {
  yad --question \
    --title="Confirmation" \
    --width=400 \
    --height=100 \
    --button="Yes:0" \
    --button="No:1" \
    --text="<span font='14'>$1</span>"
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

is_gpu() { lspci -d ::03xx | grep -qi "$1"; }

log_step() {
  echo "$(info "$step")"
}

save_step() {
  echo "${step#*]: }" | sudo tee -a "$STATE_FILE" > /dev/null
}

is_step_done() {
  sudo grep -qxF "${step#*]: }" "$STATE_FILE"
}

run_the_step() {
  is_step_done && {
    echo "$(info "$(echo "$step" | sed 's/]:.*$/]:/') skipped")"
    return 1
  }
  log_step
}

shell_alive() {
  gdbus call --session \
    --dest org.freedesktop.DBus \
    --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.NameHasOwner \
    org.gnome.Shell 2>/dev/null | grep -q "(true"
}

ext_enabled() {
  gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "'$1'"
}

ext_install() {
  for uuid in "$@"; do
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
    if [ -d "$ext_dir" ]; then
      if ext_enabled "$uuid"; then
        echo "$(info "Already installed and enabled: $uuid")"
      else
        echo "$(info "Already installed, enabling: $uuid")"
        ext_enable "$uuid"
      fi
      continue
    fi
    echo "$(info "Installing $uuid")"
    local round=0
    while [ "$round" -lt 3 ] && ! [ -d "$ext_dir" ] && shell_alive; do
      round=$((round + 1))
      {
        install_status=0
        gdbus call --session \
          --dest org.gnome.Shell.Extensions \
          --object-path /org/gnome/Shell/Extensions \
          --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid" >/tmp/ext-install.log 2>&1 || install_status=$?
        echo "$install_status" > /tmp/ext-install.status
      } &
      local install_pid=$!
      local attempts=0
      while [ "$attempts" -lt 300 ] && ! [ -d "$ext_dir" ]; do
        if shell_alive; then
          ydotool key 28:1 28:0
          sleep 1
          attempts=$((attempts + 1))
          [ -f /tmp/ext-install.status ] && [ "$attempts" -gt 10 ] && break
        else
          break
        fi
      done
      wait "$install_pid" 2>/dev/null
      rm -f /tmp/ext-install.status
      if ! shell_alive; then
        echo "$(warn "$uuid crashed GNOME Shell on attempt $round")"
      fi
    done
    if [ -d "$ext_dir" ]; then
      ext_enable "$uuid"
    elif shell_alive; then
      echo "$(warn "Failed to install $uuid after 3 attempts, see /tmp/ext-install.log")"
    else
      echo "$(warn "$uuid crashed GNOME Shell, removing it from enabled list")"
      gsettings set org.gnome.shell enabled-extensions "$(gsettings get org.gnome.shell enabled-extensions | sed "s/'$uuid'[ ,]*//; s/\[, */[/; s/, *\]/]/")"
    fi
  done
}

ext_enable() {
  for uuid in "$@"; do
    gdbus call --session \
      --dest org.gnome.Shell.Extensions \
      --object-path /org/gnome/Shell/Extensions \
      --method org.gnome.Shell.Extensions.EnableExtension "$uuid" >/dev/null 2>&1
  done
}

ext_disable() {
  for uuid in "$@"; do
    if ext_enabled "$uuid"; then
      gdbus call --session \
        --dest org.gnome.Shell.Extensions \
        --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.DisableExtension "$uuid" >/dev/null 2>&1
    fi
  done
}

[ "$EUID" -eq 0 ] && { echo "$(err 'Do not run this script with "sudo"!')" >&2; exit 1; }

sudo -v || exit 1
while true; do
  sudo -n true
  sleep 240
  kill -0 "$$" || exit
done 2>/dev/null &

echo -ne "\033]0;Fedora Overhaul 0.5.0\007"

step="[1|15]: Downloading the program data"
run_the_step && {
  (
    set -e
    if mokutil --sb-state | grep -q "enabled"; then
      throw_err "Secure Boot is enabled. Please disable Secure Boot in your BIOS/UEFI settings and run the script again."
    fi

    sudo rm -rf "$PROJECT_DIR"
    sudo mkdir -p "$PROJECT_DIR"
    mkdir -p "$WALLPAPERS_DIR" "$LIBREOFFICE_USER_DIR" "$SERVICE_DIR"
    sudo git clone --depth=1 "$GITHUB_REPO" "$PROJECT_DIR"
    sudo rm -rf "$PROJECT_DIR/.gitignore" "$PROJECT_DIR/.git/" "$PROJECT_DIR/docs/" "$PROJECT_DIR/rpmbuild/" "$PROJECT_DIR/build.sh"
    sudo touch "$STATE_FILE"
  ) || throw_err "Error while downloading the program data"
} && save_step

step="[2|15]: Configuring system package manager"
run_the_step && {
  (
    set -e
    set_dnf_conf_option "max_parallel_downloads" "15"
    set_dnf_conf_option "fastestmirror" "True"
    set_dnf_conf_option "installonly_limit" "2"
  ) || throw_err "Failed to configure system package manager"
} && save_step

step="[3|15]: Updating the system"
run_the_step && {
  (
    set -e
    sudo dnf upgrade --refresh -y --skip-unavailable && sudo flatpak update || {
      sudo dnf install -y tor
      sudo systemctl start tor
      sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
      sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
    }
    sudo fwupdmgr refresh --force >/dev/null 2>&1
    sudo fwupdmgr update -y >/dev/null 2>&1
  ) || throw_err "Failed to update the system"
} && save_step

step="[4|15]: Installing essential drivers and codecs"
run_the_step && {
  (
    set -e
    sudo dnf install -y "${RPM_FUSION_PKGS[@]}"
    sudo dnf install -y "${MEDIA_CODEC_PKGS[@]}" --allowerasing
    if is_gpu "amd"; then
      sudo dnf swap -y "${AMD_DRIVER_SWAP_PKG[@]}"
      if ! is_gpu "nvidia"; then
        sudo flatpak install -y flathub "LACT"
      fi
    fi
    if is_gpu "intel"; then
      sudo dnf install -y "${INTEL_DRIVER_PKGS[@]}"
    fi
    if is_gpu "nvidia"; then
      sudo dnf install -y "${NVIDIA_DRIVER_PKGS[@]}"
    fi
  ) || throw_err "Error while installing essential drivers and codecs"
} && save_step

step="[5|15]: Installing cachyos kernel (for better performance)"
false && run_the_step && { # Not stable for now, so disabled!
  (
    set -e
    for copr in "${CACHY_COPRS[@]}"; do
      sudo dnf copr enable -y "$copr"
    done
    sudo dnf install -y "${CACHY_TOOL_PKGS[@]}"

    sudo mkdir -p /etc/dnf/libdnf5-plugins/actions.d
    sudo tee /etc/dnf/libdnf5-plugins/actions.d/cachy-default.actions > /dev/null << 'EOF'
# After installing any kernel* package, set the latest CachyOS kernel as the default boot entry
post_transaction:kernel*:in::/usr/bin/sh -c /usr/bin/grubby\ --set-default=/boot/$(ls\ /boot\ |\ grep\ vmlinuz.*cachy\ |\ sort\ -V\ |\ tail\ -1)
EOF

    sudo dnf install -y "${CACHY_KERNEL_PKGS[@]}"
    sudo dnf install -y "${ALLOWERASING_CACHY_PKGS[@]}" --allowerasing
    sudo dracut -f
    sudo setsebool -P domain_kernel_load_modules on

    sudo scxctl start --sched lavd --mode gaming || sudo scxctl switch --sched lavd --mode gaming
    echo -e 'default_sched = "scx_lavd"\ndefault_mode = "Gaming"' | sudo tee "$SCX_LOADER_CONF" > /dev/null

    sudo grubby --update-kernel=ALL --args="amdgpu.sg_display=0"

    if lspci | grep -q "RTL8852BE"; then
      sudo tee /usr/lib/systemd/system-sleep/unload-realtek.sh > /dev/null << 'EOF'
#!/bin/sh
case "$1" in
    pre)
        scxctl stop
        /usr/sbin/modprobe -r rtw89_8852be btusb
        ;;
    post)
        /usr/sbin/modprobe rtw89_8852be btusb
        scxctl start --sched lavd --mode gaming || scxctl switch --sched lavd --mode gaming
        ;;
esac
EOF

      sudo chmod +x /usr/lib/systemd/system-sleep/unload-realtek.sh
    fi
  ) || throw_err "Error while installing cachyos kernel"
} && save_step

step="[6|15]: Installing essential programs"
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
    [ -d "$HOME/.oh-my-zsh" ] || eval "$OMZ_INSTALLER"
    if ! rpm -q msttcore-fonts-installer >/dev/null 2>&1; then
      sudo rpm --nodigest -i "$WIN_FONTS_PKG"
    fi
    
    git clone "$ADW_COLORS_REPO" "$TMP_ADW_COLORS_DIR"
    "$TMP_ADW_COLORS_DIR/setup" -i
    rm -rf "$TMP_ADW_COLORS_DIR"
  ) || throw_err "Error while installing essential programs"
} && save_step

step="[7|15]: Removing unnecessary programs"
run_the_step && {
  (
    set -e
    sudo dnf remove -y "${REMOVE_PKGS[@]}"
    cp /usr/share/applications/yad-icon-browser.desktop ~/.local/share/applications/
    echo "Hidden=true" >> ~/.local/share/applications/yad-icon-browser.desktop
  ) || throw_err "Error while removing unnecessary programs"
} && save_step

step="[8|15]: Make the grub start faster"
run_the_step && {
  (
    set -e
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  ) || throw_err "Error while generating grub config"
} && save_step

step="[9|15]: Tweaking terminal"
run_the_step && {
  (
    set -e
    if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
      echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
    fi
    sed -i 's|^ *\. /etc/bashrc|# &\n:|' "$HOME/.bashrc"
    if [ "$SHELL" != "$(which zsh)" ]; then
      chsh -s "$(which zsh)"
    fi
  ) || throw_err "Error setting up terminal"
} && save_step

step="[10|15]: Changing default music app"
run_the_step && {
  flatpak list --app | grep -q "com.github.neithern.g4music" && xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg || echo "$(warn "Failed to set default music app")"
} && save_step

step="[11|15]: Tweaking system settings"
run_the_step && {
  (
    set -e
    powerprofilesctl set performance >/dev/null 2>&1 || true
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
    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 12'

    sudo cp "$PROJECT_DIR/data/registrymodifications.xcu" "$LIBREOFFICE_USER_DIR/registrymodifications.xcu"
    for f in "${TEMPLATE_FILENAMES[@]}"; do
      sudo cp "$PROJECT_DIR/data/$f" "$HOME/Templates/$f"
    done

    if ! grep -q "file://$STEAMAPPS_DIR Steamapps" "$BOOKMARKS_FILE" 2>/dev/null; then
      sed -i "1s|^|file://$STEAMAPPS_DIR Steamapps\n|" "$BOOKMARKS_FILE"
    fi
    if ! grep -q "file://$WALLPAPERS_DIR Wallpapers" "$BOOKMARKS_FILE" 2>/dev/null; then
      sed -i "1s|^|file://$WALLPAPERS_DIR Wallpapers\n|" "$BOOKMARKS_FILE"
    fi
    nautilus -q >/dev/null 2>&1 || true
    rfkill unblock bluetooth >/dev/null 2>&1 || true
  ) || throw_err "System settings are not configured correctly"
} && save_step

step="[12|15]: Unifying appearance of GNOME applications"
run_the_step && {
  (
    set -e
    cat > "$SERVICE_DIR/overhaul-watch.service" <<EOF
[Unit]
Description=Fedora Overhaul watcher
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=$PROJECT_DIR/overhaul-watch.sh
Restart=on-failure
RestartSec=3
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus

[Install]
WantedBy=graphical-session.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable overhaul-watch.service
    systemctl --user restart overhaul-watch.service
  ) || throw_err "Error while unifying appearance of GNOME applications"
} && save_step

step="[13|15]: Installing essential gnome extensions"
run_the_step && {
  sudo systemctl enable --now ydotool.service
  daemon_ready=0
  for _ in $(seq 1 30); do
    if systemctl is-active --quiet ydotool.service && [ -S /tmp/.ydotool_socket ]; then
      daemon_ready=1
      break
    fi
    sleep 1
  done
  [ "$daemon_ready" -eq 1 ] || throw_err "ydotoold daemon failed to start ydotool.service"

  ext_install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection dash-to-dock@micxgx.gmail.com || throw_err "Error while installing gnome extensions"
} && save_step

step="Copying wallpapers and cursor files"
! is_step_done && {
  (
    set -e
    for f in "${WALLPAPER_FILENAMES[@]}"; do
      sudo cp "$PROJECT_DIR/data/wallpapers/$f" "$WALLPAPERS_DIR/$f"
    done
    sudo cp -r "$PROJECT_DIR/data/macOS/" "$CURSORS_DIR"
    gsettings set org.gnome.desktop.interface cursor-theme "macOS"
  ) || echo "$(warn "Wallpapers and cursor may not be set. If so, try again")"
} && save_step

step="Initialising steam"
! is_step_done && {
  steam -silent > /dev/null 2>&1 & disown
} && save_step

PROGRAMS=$(yad --list --checklist \
  --title="Programs to install" \
  --text="Select programs then click OK:" \
  --column="Install:CHK" \
  --column="ID" \
  --column="Description" \
  --column="Type:TEXT" \
  --print-column=2 \
  --expand-column=3 \
  --separator=" " \
  FALSE "desktop-icons"    "Enables Desktop Icons (GNOME Extension)"                               "<b><span foreground='#3584e4'>Extension</span></b>" \
  FALSE "color-picker"     "Color Picker (GNOME Extension)"                                        "<b><span foreground='#3584e4'>Extension</span></b>" \
  FALSE "update-indicator" "Updates indicator in top panel (GNOME Extension)"                      "<b><span foreground='#3584e4'>Extension</span></b>" \
  FALSE "audio-panel"      "Separate audio control in quick settings panel (GNOME Extension)"      "<b><span foreground='#3584e4'>Extension</span></b>" \
  FALSE "hidetopbar"       "Hide Top Bar (GNOME Extension)"                                        "<b><span foreground='#3584e4'>Extension</span></b>" \
  FALSE "vitals"           "System monitor in top panel (GNOME Extension)"                         "<b><span foreground='#3584e4'>Extension</span></b>" \
  
  FALSE "youtube-music"    "Best YouTube Music App for Linux"                                      "<b><span foreground='#33d17a'>App</span></b>"       \
  FALSE "vicinae"          "Vicinae - app launcher &amp; clipboard manager"                        "<b><span foreground='#33d17a'>App</span></b>"       \
  FALSE "obs-hotkeys"      "Fix OBS recording hotkeys (you want this if you will record with OBS)" "<b><span foreground='#33d17a'>App</span></b>"       \
  FALSE "minecraft"        "Minecraft (FREE VERSION)"                                              "<b><span foreground='#33d17a'>App</span></b>"       \
  --width=800 \
  --height=400)

selected() { echo "$PROGRAMS" | grep -qw "$1"; }

step="Setting up background"
! is_step_done && {
  WALLPAPER="file://$WALLPAPERS_DIR/${WALLPAPER_FILENAMES[1]}"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER"
} && save_step

step="[14|15]: Installing selected programs"; log_step
(
  set -e
  if selected "desktop-icons"; then
    ext_install ding@rastersoft.com add-to-desktop@tommimon.github.com
  fi
  if selected "color-picker"; then
    ext_install color-picker@tuberry
  fi
  if selected "update-indicator"; then
    ext_install update-extension@purejava.org
  fi
  if selected "audio-panel"; then
    ext_install quick-settings-audio-panel@rayzeq.github.io
  fi
  if selected "hidetopbar"; then
    ext_install hidetopbar@mathieu.bidon.ca
  fi
  if selected "vitals"; then
    ext_install Vitals@CoreCoding.com
  fi
) || echo "$(warn "Some extensions failed to enable. Try again")"

if selected "youtube-music"; then
  (
    set -e
    action="installing"
    if rpm -qa | grep -q youtube-music; then
      action="deleting"
      echo "$(warn "YouTube Music App is already installed")"
      ask_confirm "Do you want to delete it?" && sudo dnf remove -y youtube-music
    else
      ytm_release_url=$(echo "$YTM_DOWNLOAD_URL" | sed 's/api\.//; s/repos\///')
      echo "Installing YouTube Music App from \"$ytm_release_url\"..."
      curl -s "$YTM_DOWNLOAD_URL" | grep browser_download_url | grep x86_64.rpm | cut -d '"' -f 4 | xargs curl -L -o "$HOME/Downloads/youtube-music.rpm"
      sudo dnf install -y "$HOME/Downloads/youtube-music.rpm"
    fi
  ) || echo "$(warn "Error while $action Youtube Music App. Try again")"
fi

if selected "vicinae"; then
  eval "$VICINAE_INSTALLER" || echo "$(warn "Vicinae installation failed. Try later by running this program again")"
fi

if selected "obs-hotkeys"; then
  eval "$OBS_HOTKEYS_INSTALLER" || echo "$(warn "OBS Hotkeys installation failed. Try later by running this program again")"
fi

if selected "minecraft"; then
  eval "$MC_INSTALLER" || echo "$(warn "Minecraft installation failed. Try later by running this program again")"
fi

step="[15|15]: Prompt for reboot"
run_the_step && {
  yad --info \
    --title="Setup Complete" \
    --text="Your Fedora installation is ready to use\n\nDo you want to reboot now?" \
    --width=400 \
    --button="Reboot now:0" \
    --button="Later:1" && systemctl reboot
} && save_step