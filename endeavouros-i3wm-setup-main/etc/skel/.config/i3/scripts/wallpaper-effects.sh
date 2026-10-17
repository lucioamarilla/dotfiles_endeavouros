#!/bin/bash
# wallpaper-effects.sh - efectos ImageMagick sobre el wallpaper actual (SUPER+SHIFT+W)
# Adaptado de JaKooLit UserScripts/WallpaperEffects.sh para feh/X11

wallpaper_current="$HOME/.config/i3/.wallpaper_current"
wallpaper_output="$HOME/.config/i3/.wallpaper_modified"
rofi_theme="$HOME/.config/rofi/config-wallpaper-effect.rasi"

if [[ ! -f "$wallpaper_current" ]]; then
  notify-send "Wallpaper Effects" "No hay wallpaper guardado. Usa SUPER+W primero."
  exit 1
fi

src=$(cat "$wallpaper_current")
if [[ ! -f "$src" ]]; then
  notify-send "Wallpaper Effects" "El wallpaper actual ya no existe: $src"
  exit 1
fi

declare -A effects=(
  ["Black & White"]="convert $src -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
  ["Blurred"]="convert $src -blur 0x10 $wallpaper_output"
  ["Charcoal"]="convert $src -charcoal 0x5 $wallpaper_output"
  ["Edge Detect"]="convert $src -edge 1 $wallpaper_output"
  ["Emboss"]="convert $src -emboss 0x5 $wallpaper_output"
  ["Negate"]="convert $src -negate $wallpaper_output"
  ["Oil Paint"]="convert $src -paint 4 $wallpaper_output"
  ["Posterize"]="convert $src -posterize 4 $wallpaper_output"
  ["Sepia Tone"]="convert $src -sepia-tone 65% $wallpaper_output"
  ["Solarize"]="convert $src -solarize 80% $wallpaper_output"
  ["Sharpen"]="convert $src -sharpen 0x5 $wallpaper_output"
  ["Vignette"]="convert $src -vignette 0x3 $wallpaper_output"
  ["Zoomed"]="convert $src -gravity Center -extent 1:1 $wallpaper_output"
)

pidof rofi >/dev/null && pkill rofi

options=("No Effects")
for effect in "${!effects[@]}"; do
  options+=("$effect")
done

choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -i -config "$rofi_theme" -mesg "Efectos con ImageMagick")

[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "No Effects" ]]; then
  feh --no-feh-bg --bg-fill "$src"
  echo "$src" > "$wallpaper_current"
  notify-send "Wallpaper Effects" "Sin efectos (original)"
  exit 0
fi

if [[ -n "${effects[$choice]}" ]]; then
  notify-send "Wallpaper Effects" "Aplicando: $choice"
  eval "${effects[$choice]}"
  feh --no-feh-bg --bg-fill "$wallpaper_output"
  # el estado apunta al modificado para poder encadenar efectos
  echo "$wallpaper_output" > "$wallpaper_current"
  notify-send "Wallpaper Effects" "$choice aplicado"
else
  notify-send "Wallpaper Effects" "Efecto desconocido: $choice"
fi
