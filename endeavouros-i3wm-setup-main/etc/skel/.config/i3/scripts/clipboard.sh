#!/bin/bash
# clipboard.sh - gestor de clipboard con greenclip + rofi (SUPER+ALT+V)
# requiere: yay -S rofi-greenclip y greenclip daemon corriendo

rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='👀 CTRL+DEL = borrar entrada · ALT+DEL = borrar todo'

pidof rofi >/dev/null && pkill rofi

if ! pgrep -x greenclip >/dev/null; then
  greenclip daemon >/dev/null 2>&1 &
  sleep 0.5
fi

rofi -modi "clipboard:greenclip print" -show clipboard \
  -config "$rofi_theme" -mesg "$msg" \
  -kb-custom-1 "Control-Delete" \
  -kb-custom-2 "Alt-Delete" \
  || {
    # custom keys: 10 = Ctrl-Del, 11 = Alt-Del
    case $? in
      10) pidof greenclip >/dev/null && greenclip clear ;;
      11) pidof greenclip >/dev/null && greenclip clear && notify-send "Clipboard" "Historial borrado" ;;
    esac
  }
