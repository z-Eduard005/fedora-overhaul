#!/bin/bash
apply_accent() {
  local ACCENT
  ACCENT=$(gsettings get org.gnome.desktop.interface accent-color | tr -d "'")
  gsettings set org.gnome.desktop.interface icon-theme "Adwaita-$ACCENT"

  unlink "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
  unlink "$HOME/.config/gtk-3.0/assets" 2>/dev/null

  for file in "$HOME/.config/gtk-3.0/gtk.css"; do
    if [ -f "$file" ]; then
      cp "$file" "${file}.overhaul.bak"
    fi
  done

  cat <<EOF > "$HOME/.config/gtk-3.0/gtk.css"
@define-color accent_blue #3584e4;
@define-color accent_teal #2190a4;
@define-color accent_green #3a944a;
@define-color accent_yellow #c88800;
@define-color accent_orange #ed5b00;
@define-color accent_red #e62d42;
@define-color accent_pink #d56199;
@define-color accent_purple #9141ac;
@define-color accent_slate #6f8396;
@define-color accent_bg_color @accent_$ACCENT;
EOF
}

apply_theme() {
  local SCHEME
  SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")

  if [ "$SCHEME" = "prefer-dark" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  else
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
  fi
}

apply_accent
apply_theme

gsettings monitor org.gnome.desktop.interface | while IFS= read -r line; do
  case "$line" in
    accent-color:*) apply_accent ;;
    color-scheme:*) apply_theme ;;
  esac
done