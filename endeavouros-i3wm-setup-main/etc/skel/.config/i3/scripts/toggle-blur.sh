#!/bin/bash
# toggle-blur.sh - activa/desactiva blur de picom (SUPER+ALT+O)

CONF="$HOME/.config/picom/picom.conf"
RUNTIME="$HOME/.cache/picom-runtime.conf"
STATE="$HOME/.cache/picom-blur-state"

if [[ ! -f "$CONF" ]]; then
  notify-send "Picom" "No existe ~/.config/picom/picom.conf"
  exit 1
fi

mkdir -p "$HOME/.cache"
cp "$CONF" "$RUNTIME"

# estado por defecto: encendido (el config trae blur activo)
if [[ ! -f "$STATE" ]] || grep -q "^1$" "$STATE"; then
  echo 'blur-background = false;' >> "$RUNTIME"
  echo 'blur-method = "none";' >> "$RUNTIME"
  echo 0 > "$STATE"
  notify-send "Picom" "Blur OFF"
else
  echo 'blur-background = true;' >> "$RUNTIME"
  echo 'blur-method = "dual_kawase";' >> "$RUNTIME"
  echo 'blur-strength = 7;' >> "$RUNTIME"
  echo 1 > "$STATE"
  notify-send "Picom" "Blur ON"
fi

pkill picom
sleep 0.3
picom -b --config "$RUNTIME"
