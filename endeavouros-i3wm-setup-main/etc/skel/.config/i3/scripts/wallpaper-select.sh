#!/bin/bash
# wallpaper-select.sh - selector de wallpapers con rofi + feh (SUPER+W)
# Adaptado de JaKooLit UserScripts/WallpaperSelect.sh para i3/X11

wallDIR="$HOME/Pictures/wallpapers"
wallpaper_state="$HOME/.config/i3/.wallpaper_current"
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"

# wallpaper por defecto de EndeavourOS si no existe el dir
default_wall="/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png"

if [[ ! -d "$wallDIR" ]]; then
  notify-send "Wallpapers" "No existe $wallDIR — creándolo"
  mkdir -p "$wallDIR"
  [[ -f "$default_wall" ]] && cp "$default_wall" "$wallDIR/"
fi

# mata rofi si ya corre
pidof rofi >/dev/null && pkill rofi

mapfile -d '' PICS < <(find -L "$wallDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "Wallpapers" "No hay imágenes en $wallDIR"
  exit 1
fi

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"

menu() {
  printf "%s\n" ". random"
  for pic_path in "${PICS[@]}"; do
    pic_name=$(basename "$pic_path")
    printf "%s\x00icon\x1f%s\n" "${pic_name%.*}" "$pic_path"
  done
}

choice=$(menu | rofi -i -dmenu -config "$rofi_theme" -mesg "Elige un wallpaper (feh)")

if [[ -z "$choice" ]]; then
  exit 0
fi

choice=$(echo "$choice" | xargs)

if [[ "$choice" == ". random" ]]; then
  selected="$RANDOM_PIC"
else
  choice_basename=$(echo "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
  selected=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)
fi

if [[ -z "$selected" || ! -f "$selected" ]]; then
  notify-send "Wallpapers" "No se encontró: $choice"
  exit 1
fi

feh --no-feh-bg --bg-fill "$selected"
echo "$selected" > "$wallpaper_state"
notify-send -i "$selected" "Wallpaper" "$(basename "$selected")"
