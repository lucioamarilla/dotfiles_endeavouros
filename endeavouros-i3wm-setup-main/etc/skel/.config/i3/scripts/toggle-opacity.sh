#!/bin/bash
# toggle-opacity.sh - opacidad de la ventana activa on/off (SUPER+CTRL+O)

wid=$(xdotool getactivewindow 2>/dev/null) || exit 1
current=$(xprop -id "$wid" _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $5}')

# sin valor o totalmente opaca (0xffffffff) -> transparencia; si no -> opaca
if [[ -z "$current" || "$current" == "0xffffffff" || "$current" == "4294967295" ]]; then
  picom-trans -w "$wid" -t 85
  notify-send "Picom" "Ventana transparente (85%)"
else
  picom-trans -w "$wid" -o
  notify-send "Picom" "Ventana opaca"
fi
