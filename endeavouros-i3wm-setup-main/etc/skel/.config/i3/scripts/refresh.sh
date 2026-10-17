#!/bin/bash
# refresh.sh - recarga i3 + notificaciones + greenclip (SUPER+ALT+R)

# recarga config de i3 (no reinicia sesión)
i3-msg reload >/dev/null

# reinicia dunst
pkill dunst 2>/dev/null
sleep 0.3
dunst &
disown

# reinicia greenclip si está instalado
if command -v greenclip >/dev/null 2>&1; then
  pkill greenclip 2>/dev/null
  sleep 0.3
  greenclip daemon >/dev/null 2>&1 &
  disown
fi

notify-send "i3" "Recargado: i3 + dunst + greenclip"
