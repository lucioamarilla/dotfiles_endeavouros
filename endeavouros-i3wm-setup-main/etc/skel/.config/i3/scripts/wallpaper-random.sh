#!/bin/bash
# wallpaper-random.sh - wallpaper aleatorio con feh (CTRL+ALT+W)

wallDIR="$HOME/Pictures/wallpapers"
wallpaper_state="$HOME/.config/i3/.wallpaper_current"

mapfile -d '' PICS < <(find -L "$wallDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) -print0 2>/dev/null)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "Wallpapers" "No hay imágenes en $wallDIR"
  exit 1
fi

selected="${PICS[$((RANDOM % ${#PICS[@]}))]}"

feh --no-feh-bg --bg-fill "$selected"
echo "$selected" > "$wallpaper_state"
notify-send -i "$selected" "Wallpaper random" "$(basename "$selected")"
