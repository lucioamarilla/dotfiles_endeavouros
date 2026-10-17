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

### 1. Clonar el repo

```bash
git clone https://github.com/lucioamarilla/dotfiles_endeavouros.git ~/dotfiles_endeavouros
cd ~/dotfiles_endeavouros/endeavouros-i3wm-setup-main
```

### 2. Instalar

**Opción A — instalador automático (recomendada):**

```bash
./i3_install
```

El script:

- Instala los paquetes necesarios con `pacman` (i3-wm, kitty, rofi, picom, feh, scrot, etc.)
- Instala `rofi-greenclip` desde la AUR con `yay`
- Copia los dotfiles de **este repo** a `$HOME` (i3, kitty, rofi, picom, dunst, .profile)
- Da permisos a los scripts

> **Nota importante**: este instalador **no** usa `eos-settings-i3wm` (el paquete genérico de EndeavourOS), así que evita el error de conflicto con `eos-settings-xfce4`. Los configs de este repo ya son completos; no necesitas ese paquete.

**Opción B — manual (para revisar qué se copia):**

```bash
# dependencias (repo oficial)
sudo pacman -S --needed i3-wm i3blocks i3lock dunst rofi feh picom \
    kitty thunar scrot xclip xdotool playerctl \
    polkit-gnome dex xss-lock jq yad imagemagick

# AUR
yay -S rofi-greenclip

# dotfiles
cp -r etc/skel/.config/i3 ~/.config/
mkdir -p ~/.config/kitty && cp -r etc/skel/.config/kitty/* ~/.config/kitty/
cp -r etc/skel/.config/rofi/* ~/.config/rofi/
mkdir -p ~/.config/picom && cp etc/skel/.config/picom/picom.conf ~/.config/picom/
cp -r etc/skel/.config/dunst ~/.config/
cp etc/skel/.profile ~/

# permisos
chmod +x ~/.config/i3/scripts/*
```

### 3. Crear tu carpeta de wallpapers

```bash
mkdir -p ~/Pictures/wallpapers
# copia tus imágenes ahí; el selector (SUPER+W) y el random (CTRL+ALT+W) la usan
```

### 4. Cerrar sesión y entrar en i3

En el gestor de inicio de sesión (ly/sddm/gdm) elige la sesión **i3**. Si es la primera vez, i3 te preguntará si quieres generar el config por defecto: elige **NO** (ya tienes el config copiado).

### 5. Verificar

- `SUPER+Return` debe abrir **kitty**
- `SUPER+D` debe abrir **rofi**
- `SUPER+H` o `F1` debe abrir el cheat sheet
- `SUPER+W` debe abrir el selector de wallpapers (si no hay imágenes, agrégales a `~/Pictures/wallpapers`)

## Solución de problemas

### Error: "eos-settings-i3wm: /etc/skel/.Xresources ya existe (es parte de eos-settings-xfce4)"

Si aparece al instalar `eos-settings-i3wm` a mano (por ejemplo desde la lista de paquetes oficial con `pacman -S --needed - < i3`), tienes XFCE settings instalado y chocan los archivos de skel. Soluciones:

```bash
# si NO usas XFCE: quitar el settings de XFCE y reinstalar
sudo pacman -Rns eos-settings-xfce4
sudo pacman -S eos-settings-i3wm

# si SÍ usas XFCE: sobreescribir solo los 3 archivos en conflicto
# (ojo: es .Xresources, no .Xsources)
sudo pacman -S eos-settings-i3wm \
    --overwrite '/etc/skel/.Xresources' \
    --overwrite '/etc/skel/.config/autostart/firewall-applet.desktop' \
    --overwrite '/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml'
```

> Con el instalador de este repo (`./i3_install`) no necesitas `eos-settings-i3wm`: instala los paquetes directamente y copia los configs desde `etc/skel/` de este repo.

### La sesión i3 no aparece en el login (display manager)

Casi siempre es porque `i3-wm` no está instalado. Si una instalación por pacman falla (por ejemplo por el conflicto de arriba), **se cancela toda la transacción** y ningún paquete se instala — ni siquiera `i3-wm`.

Diagnóstico:

```bash
pacman -Q i3-wm
ls /usr/share/xsessions/
```

Si `i3-wm` no está instalado o falta `/usr/share/xsessions/i3.desktop`:

```bash
sudo pacman -S --needed i3-wm i3blocks i3lock
```

Tras eso, cierra sesión y la sesión **i3** debe aparecer en el selector del display manager.

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
├── i3_install                  # instalador (paquetes + copia dotfiles de este repo)
├── i3_install_isomode          # instalador para modo ISO (lightdm)
└── packages-repository.txt     # lista de paquetes oficial EndeavourOS (referencia)
```

## Créditos

- [endeavouros-team/endeavouros-i3wm-setup](https://github.com/endeavouros-team/endeavouros-i3wm-setup) — base del setup i3
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) — keybindings, scripts de wallpapers/rofi/emoji y estilo KooL
- [killajoe](https://github.com/killajoe) (Joe Kamprad) — mantenimiento del setup original de EndeavourOS

## Licencia

Ver [LICENSE](LICENSE).
