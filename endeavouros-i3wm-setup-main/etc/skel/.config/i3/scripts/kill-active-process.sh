#!/bin/bash
# kill-active-process.sh - mata el proceso de la ventana activa (SUPER+SHIFT+Q)
# A diferencia de "kill" (WM_DELETE), esto hace kill -9 al PID real

pid=$(xprop -id "$(xdotool getactivewindow)" _NET_WM_PID 2>/dev/null | awk '{print $3}')

if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  kill -9 "$pid"
  notify-send "Window" "Proceso $pid finalizado"
else
  # fallback: cierra la ventana vía WM
  i3-msg kill
fi
