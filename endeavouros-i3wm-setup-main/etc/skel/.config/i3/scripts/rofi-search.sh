#!/bin/bash
# rofi-search.sh - búsqueda Google con rofi (SUPER+S)
# Adaptado de JaKooLit scripts/RofiSearch.sh

Search_Engine="https://www.google.com/search?q={}"
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ busca en tu navegador por defecto'

pidof rofi >/dev/null && pkill rofi

query=$(echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg")
[[ -z "$query" ]] && exit 0

xdg-open "${Search_Engine/\{\}/$(printf '%s' "$query" | jq -sRr @uri)}"
