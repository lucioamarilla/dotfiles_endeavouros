# endeavouros-i3wm-setup (KooL Edition)

Dotfiles para **i3 window manager** en [EndeavourOS](https://endeavouros.com), adaptados para replicar los keybindings y el flujo de trabajo de [KooL Hyprland](https://github.com/JaKooLit/Hyprland-Dots) (JaKooLit) sobre X11.

Basado en el setup oficial de EndeavourOS ([endeavouros-team/endeavouros-i3wm-setup](https://github.com/endeavouros-team/endeavouros-i3wm-setup), maintainer [killajoe](https://github.com/killajoe)).

## Qué incluye este setup

- **Terminal**: [kitty](https://sw.kovidgoyal.net/kitty/) (config idéntica al setup KooL: opacity 0.9, FantasqueSansM Nerd Font)
- **Keybindings estilo KooL Hyprland**: mismo mapa de teclas que tu setup de Hyprland (SUPER+Q cerrar, SUPER+B navegador, SUPER+E Thunar, SUPER+W wallpapers, screenshots con Print, etc.)
- **Wallpapers con feh + rofi**: selector visual, aleatorio y efectos con ImageMagick
- **Clipboard manager**: greenclip + rofi (SUPER+Alt+V)
- **Rofi tools**: búsqueda Google, emojis, keybinds buscables
- **picom con blur dual_kawase**: toggle de blur y opacidad en caliente
- **Dropdown terminal** con kitty (SUPER+Shift+Return)

## Requisitos

- EndeavourOS instalado con i3 (o i3 instalado aparte)
- `yay` (incluido en EndeavourOS)

## Instalación

### 1. Instalar dependencias

```bash
# paquetes del repo oficial
sudo pacman -S --needed kitty thunar firefox feh scrot i3lock dunst picom \
    rofi xclip xdotool imagemagick playerctl amixer alsa-utils \
    polkit-gnome dex xss-lock i3blocks jq yad

# paquetes de la AUR
yay -S rofi-greenclip
```

> `rofi-greenclip` es necesario solo para el clipboard manager (SUPER+Alt+V). Si no lo instalas, comenta la línea `greenclip daemon` en el config de i3.

### 2. Clonar el repo

```bash
git clone <URL-de-este-repo> ~/dotfiles_endeavouros
cd ~/dotfiles_endeavouros/endeavouros-i3wm-setup-main
```

### 3. Copiar los dotfiles a tu home

**Opción A — manual (recomendada, puedes revisar antes):**

```bash
# i3 config + scripts
cp -r etc/skel/.config/i3 ~/.config/

# kitty (terminal)
mkdir -p ~/.config/kitty
cp -r etc/skel/.config/kitty/* ~/.config/kitty/

# rofi (temas y configs)
cp -r etc/skel/.config/rofi/* ~/.config/rofi/

# picom (compositor con blur)
mkdir -p ~/.config/picom
cp etc/skel/.config/picom/picom.conf ~/.config/picom/

# dunst (notificaciones)
cp -r etc/skel/.config/dunst ~/.config/

# feh wallpaper por defecto de EndeavourOS (opcional)
# lo gestiona el autostart del config de i3

# resto del skel (gtk, perfiles, etc.) según necesites
cp etc/skel/.profile ~/
cp etc/skel/set_once.sh ~/
```

**Opción B — con el instalador original de EndeavourOS** (sobreescribe tu `$HOME` actual, úsalo solo en un sistema limpio):

```bash
./i3_install
```

### 4. Dar permisos a los scripts

```bash
chmod +x ~/.config/i3/scripts/*
```

### 5. Crear tu carpeta de wallpapers

```bash
mkdir -p ~/Pictures/wallpapers
# copia tus imágenes ahí; el selector (SUPER+W) y el random (CTRL+ALT+W) la usan
```

### 6. Cerrar sesión y entrar en i3

En el gestor de inicio de sesión (ly/sddm/gdm) elige la sesión **i3**. Si es la primera vez, i3 te preguntará si quieres generar el config por defecto: elige **NO** (ya tienes el config copiado).

### 7. Verificar

- `SUPER+Return` debe abrir **kitty**
- `SUPER+D` debe abrir **rofi**
- `SUPER+H` o `F1` debe abrir el cheat sheet
- `SUPER+W` debe abrir el selector de wallpapers (si no hay imágenes, agrégales a `~/Pictures/wallpapers`)

## Keybindings principales

La lista completa está en `~/.config/i3/keybindings` y también puedes verla con `SUPER+Shift+K` (buscable con rofi).

| Tecla | Acción |
|---|---|
| `SUPER+Return` | Terminal (kitty) |
| `SUPER+Shift+Return` | Terminal dropdown |
| `SUPER+Q` / `SUPER+Shift+Q` | Cerrar ventana / matar proceso |
| `SUPER+B` / `SUPER+E` / `SUPER+D` | Navegador / Thunar / rofi |
| `SUPER+S` | Búsqueda Google (rofi) |
| `SUPER+W` / `SUPER+Shift+W` / `CTRL+ALT+W` | Wallpaper selector / efectos / random |
| `SUPER+Alt+V` | Clipboard manager (greenclip) |
| `SUPER+Alt+E` | Emojis (rofi) |
| `SUPER+Shift+K` | Keybinds buscables (rofi) |
| `Print` (+Shift/Ctrl/Alt) | Screenshots (scrot) |
| `CTRL+ALT+P` | Power menu |
| `CTRL+ALT+L` | Lock screen |
| `CTRL+ALT+B` | Ocultar/mostrar barra |
| `SUPER+Alt+O` / `SUPER+Ctrl+O` | Toggle blur / opacidad (picom) |
| `SUPER+flechas` / `+Ctrl` / `+Shift` | Foco / mover / resize |
| `SUPER+Shift+F` / `SUPER+Ctrl+F` | Fullscreen / fake fullscreen |
| `SUPER+Space` | Toggle flotar |
| `SUPER+Alt+L` | Ciclar layouts |
| `SUPER+H` / `F1` | Cheat sheet |

## Configuración avanzada

### Terminal por defecto

El terminal es **kitty** en:

- `~/.config/i3/config` → `bindsym $mod+Return exec --no-startup-id kitty`
- `~/.profile` → `export TERMINAL=kitty` (si existe la línea, cámbiala)

### picom / blur

El config está en `~/.config/picom/picom.conf` (backend glx, blur dual_kawase, corner-radius 10). Se autostartea desde i3.

- `SUPER+Alt+O` → activa/desactiva blur (guarda estado en `~/.cache/picom-blur-state`)
- `SUPER+Ctrl+O` → transparencia de la ventana activa (usa `picom-trans`)

Si tu GPU tiene problemas con glx, cambia `backend = "glx"` a `"xrender"` en el config de picom.

### greenclip

El daemon arranca con i3. Si SUPER+Alt+V no abre nada:

```bash
greenclip daemon &
```

### Wallpaper de inicio

El autostart usa el wallpaper de EndeavourOS:

```
feh --bg-fill /usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png
```

Cámbialo por el que quieras, o usa `SUPER+W` tras iniciar sesión.

## Estructura del repo

```
endeavouros-i3wm-setup-main/
├── etc/skel/.config/
│   ├── i3/
│   │   ├── config              # config principal de i3 (keybinds estilo KooL)
│   │   ├── i3blocks.conf       # barra
│   │   ├── keybindings         # cheat sheet de atajos
│   │   └── scripts/            # scripts (wallpapers, rofi, picom, etc.)
│   ├── kitty/                  # kitty.conf + tema
│   ├── rofi/                   # temas rasi (incluye search/emoji/clipboard/keybinds)
│   ├── picom/picom.conf        # compositor con blur
│   └── dunst/                  # notificaciones
├── i3_install                  # instalador original EndeavourOS (opcional)
└── packages-repository.txt     # lista de paquetes oficial EndeavourOS
```

## Créditos

- [endeavouros-team/endeavouros-i3wm-setup](https://github.com/endeavouros-team/endeavouros-i3wm-setup) — base del setup i3
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) — keybindings, scripts de wallpapers/rofi/emoji y estilo KooL
- [killajoe](https://github.com/killajoe) (Joe Kamprad) — mantenimiento del setup original de EndeavourOS

## Licencia

Ver [LICENSE](LICENSE).
