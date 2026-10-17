#!/bin/bash
# rofi-keybinds.sh - keybinds buscables con rofi (SUPER+SHIFT+K)
# Adaptado de JaKooLit scripts/KeyBinds.sh para i3

i3_config="$HOME/.config/i3/config"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: ENTER/clic no ejecutan nada, es solo lectura'

pidof rofi >/dev/null && pkill rofi

if [[ ! -f "$i3_config" ]]; then
  notify-send "Keybinds" "No existe $i3_config"
  exit 1
fi

# solo líneas bindsym activas (ignora comentarios)
keybinds=$(grep -E '^\s*bindsym' "$i3_config")

if [[ -z "$keybinds" ]]; then
  notify-send "Keybinds" "No se encontraron bindsym"
  exit 1
fi

# $mod -> SUPER para leer
display_keybinds=$(echo "$keybinds" | sed 's/\$mod/SUPER/g; s/Mod1/ALT/g; s/exec --no-startup-id //; s/bindsym //')

echo "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
