# Tutorial definitivo: EndeavourOS en ThinkPad L15 Gen 1 (256 GB)

Migración completa desde **Ubuntu** hasta **EndeavourOS** (Arch-based) con
**i3wm + XFCE**, perfil **DevOps/Redes**, con backup de datos hacia el disco
de 2 TB de tu PC de escritorio (NTFS) por red/Samba, y reinstalación selectiva
de apps (cribadas app-por-app).

| Dato | Valor |
|---|---|
| Laptop | ThinkPad L15 Gen 1 (AMD Ryzen PRO + Radeon Vega, Wi-Fi Intel AX200, BT, 8 GB RAM) |
| SSD | 256 GB — particiones: EFI 1 GB · swap 16 GB (hibernación) · ext4 ~239 GB |
| SO origen | Ubuntu (XFCE + Hyprland), 2 particiones, sin Windows |
| SO destino | EndeavourOS, borrado total |
| Escritorios | XFCE (respaldo GUI) + i3wm (principal, dotfile KooL) |
| Backup | ThinkPad → disco NTFS 2 TB de la PC escritorio, vía Samba/red |
| Datos a rescatar | `Facultad`, `Descargas`, claves SSH/GPG, dotfiles, configs (nvim/kitty/btop/opencode). Proyectos → git/nube |
| Sync | Firefox Account (LibreWolf) + VS Code Settings Sync — no se copian perfiles |

> **Regla de oro:** este tutorial borra el SSD de la ThinkPad. El backup se
> verifica (paso 1.6) **antes** de arrancar el instalador. Sin verificación,
> no se formatea.

---

## Fase 1 — Backup: ThinkPad (Ubuntu) → PC escritorio (disco NTFS 2 TB) por Samba

El destino es el **disco NVMe de 2 TB con NTFS** dentro de tu PC de escritorio
(actualmente sin montar). Lo compartimos por red y copiamos desde la ThinkPad.

### 1.1 Montar el disco NTFS en la PC escritorio

```bash
# Identificar el disco (el de ~1.9T con partición NTFS)
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT

# Crear punto de montaje y montar (ntfs-3g viene en EndeavourOS/Ubuntu)
sudo mkdir -p /mnt/datos2tb
sudo ntfs-3g /dev/nvme0n1p3 /mnt/datos2tb

# Verificar
df -h /mnt/datos2tb
```

Para montaje automático, agregá a `/etc/fstab` (reemplazá UUID si querés):
```bash
# Obtener UUID
sudo blkid /dev/nvme0n1p3
# Línea en /etc/fstab:
/dev/nvme0n1p3  /mnt/datos2tb  ntfs-3g  defaults,nofail  0  0
```

### 1.2 Crear la carpeta de backup y el usuario Samba

```bash
# Carpeta de destino
sudo mkdir -p /mnt/datos2tb/backup_thinkpad
sudo chown -R "$USER":"$USER" /mnt/datos2tb/backup_thinkpad

# Instalar Samba (Ubuntu: sudo apt install samba)
sudo apt install -y samba

# Crear usuario Samba (usá tu usuario; te va a pedir contraseña Samba)
sudo smbpasswd -a "$USER"
```

### 1.3 Compartir la carpeta por Samba

Editá `/etc/samba/smb.conf` y agregá al final:

```ini
[backup]
   path = /mnt/datos2tb/backup_thinkpad
   browseable = yes
   read only = no
   writable = yes
   valid users = TU_USUARIO
   create mask = 0644
   directory mask = 0755
```

Reiniciá y habilitá el firewall si lo usás:

```bash
sudo systemctl restart smbd nmbd
sudo systemctl enable --now smbd nmbd
# Solo si usás ufw:
# sudo ufw allow samba
```

### 1.4 (Alternativa) Si el destino lo abre Windows 10/11

Por si más tarde arrancás Windows en ese disco u otra máquina:

1. Clic derecho en la carpeta → *Propiedades* → *Compartir* → *Compartir…*
2. Agregá tu usuario con permiso *Lectura/Escritura* → *Compartir*
3. En *Centro de redes* → *Cambiar opciones de compatibilidad*:
   * Activar **descubrimiento de red**
   * Activar **compartición de archivos e impresoras**
4. La carpeta queda en `\\NOMBRE-PC\NombreDelRecurso` — la usás desde Ubuntu
   en Nautilus (`smb://IP_DEL_PC/NombreDelRecurso`) o montándola con `cifs`.

### 1.5 Desde la ThinkPad: montar el share y copiar con rsync

En la ThinkPad (Ubuntu, todavía sin tocar):

```bash
# Dependencias
sudo apt install -y rsync cifs-utils

# Descubrir la PC destino (misma red)
ip -4 addr show          # IP de la ThinkPad
# En la PC escritorio: hostname -I   → anotá esa IP, llamala $IP_DESTINO

# Montar el share
mkdir -p ~/mnt_backup
sudo mount -t cifs //$IP_DESTINO/backup ~/mnt_backup \
  -o username=TU_USUARIO,uid=$(id -u),gid=$(id -g)

# Verificar que se ve vacío y escribible
touch ~/mnt_backup/.test && rm ~/mnt_backup/.test && echo "OK"
```

### 1.6 Copia con rsync (dry-run primero, después real)

```bash
# PRUEBA (dry-run): qué se copiaría, sin copiar nada
rsync -avhn --progress \
  --exclude='.cache/' \
  --exclude='snap/' \
  --exclude='.local/share/Trash/' \
  --exclude='VirtualBox VMs/' \
  --exclude='virtualbox/' \
  --exclude='vmware/' \
  --exclude='sistemas_operativos_iso/' \
  --exclude='*.iso' \
  ~/Facultad ~/Descargas ~/.ssh ~/.gnupg \
  ~/.config/hypr ~/.config/waybar ~/.config/rofi \
  ~/.config/swaync ~/.config/wlogout ~/.config/wallust \
  ~/.config/nvim ~/.config/kitty ~/.config/btop \
  ~/.config/opencode ~/proyectos \
  ~/mnt_backup/

# Real (misma línea sin -n): puede tardar según la red/disco
rsync -avh --progress \
  --exclude='.cache/' \
  --exclude='snap/' \
  --exclude='.local/share/Trash/' \
  --exclude='VirtualBox VMs/' \
  --exclude='*.iso' \
  ~/Facultad ~/Descargas ~/.ssh ~/.gnupg \
  ~/.config/hypr ~/.config/waybar ~/.config/rofi \
  ~/.config/swaync ~/.config/wlogout ~/.config/wallust \
  ~/.config/nvim ~/.config/kitty ~/.config/btop \
  ~/.config/opencode ~/proyectos \
  ~/mnt_backup/
```

> **Proyectos:** si preferís git/nube, cloná los repos a mano en vez de copiar
> la carpeta `~/proyectos` (o copiala igual como respaldo y después re-cloná).

### 1.7 Verificación (OBLIGATORIA antes de formatear)

```bash
# Contar archivos en origen y destino
find ~/Facultad ~/Descargas -type f | wc -l
find ~/mnt_backup/Facultad ~/mnt_backup/Descargas -type f | wc -l

# Tamaños comparados
du -sh ~/Facultad ~/Descargas
du -sh ~/mnt_backup/Facultad ~/mnt_backup/Descargas

# Claves SSH presentes
ls -la ~/mnt_backup/.ssh/
```

### 1.8 Exportar listas de software (referencia futura)

En la ThinkPad:
```bash
mkdir -p ~/mnt_backup/listas
dpkg --get-selections > ~/mnt_backup/listas/dpkg-selections.txt
apt-mark showmanual    > ~/mnt_backup/listas/apt-manual.txt
snap list              > ~/mnt_backup/listas/snap-list.txt 2>/dev/null || true
flatpak list           > ~/mnt_backup/listas/flatpak-list.txt 2>/dev/null || true
```

### 1.9 (Opcional) Guardar imágenes Docker

En la ThinkPad:
```bash
docker images --format "{{.Repository}}:{{.Tag}}" | while read img; do
  docker save "$img" -o ~/mnt_backup/listas/docker-$(echo "$img" | tr '/:' '__').tar
done
```
> No lo hicimos obligatorio por tu decisión de descartar las imágenes; dejado
> como opción por si cambias de idea. Si no: los contenedores se reconstruyen
> con sus `docker-compose.yml`/Dockerfiles.

### 1.10 Desmontar

```bash
# ThinkPad
sudo umount ~/mnt_backup

# PC escritorio (dejalo montado si querés acceso inmediato después)
# sudo umount /mnt/datos2tb
```

---

## Fase 2 — USB booteable con EndeavourOS

1. La ISO ya la tenés en la PC escritorio:
   `~/Descargas/EndeavourOS_Titan-Nova-2026.08.15.iso`
2. Verificá la suma SHA256 contra la oficial (https://endeavouros.com → Download):
   ```bash
   sha256sum ~/Descargas/EndeavourOS_Titan-Nova-2026.08.15.iso
   ```
3. Grabá la ISO en un USB ≥ 4 GB:
   * **Linux:** `dd` o GNOME Disks / balenaEtcher
     ```bash
     sudo dd if=~/Descargas/EndeavourOS_Titan-Nova-2026.08.15.iso \
              of=/dev/sdX bs=4M status=progress && sync
     ```
     (reemplazá `/dev/sdX` por el dispositivo del USB — **sin** número de
     partición; verificá con `lsblk` antes)
   * **Windows:** balenaEtcher o Rufus (modo ISO, GPT/UEFI)
4. Dejá el USB conectado a la ThinkPad y reiniciá.

---

## Fase 3 — UEFI del ThinkPad L15 Gen 1

1. Al arrancar: **F1** (o Fn+F1) para entrar al UEFI/BIOS de ThinkPad.
2. Opciones recomendadas:
   * **Secure Boot → Disabled** *(EndeavourOS lo soporta con su ISO firmada,
     pero desactivarlo elimina una capa de problemas; si lo dejás activo y el
     arranque falla, desactivalo)*
   * **Boot → USB Storage Boot → Enabled**
   * **UEFI Boot Order:** USB primero (F12 en arranque para elegir temporalmente)
   * **Fast Startup / "Windows Boot Manager":** irrelevante tras el borrado
3. Guardá y salí (F10). El USB debe mostrar el menú de EndeavourOS.

---

## Fase 4 — Particionado y instalación (Calamares)

### 4.1 Tabla de particiones — 256 GB con hibernación

| # | Partición | Tamaño | Tipo | Montaje | Notas |
|---|---|---|---|---|---|
| 1 | `efi` | **1 GB** | FAT32, flag `boot`/ESP | `/boot/efi` | Compartida conceptualmente con futuros SO; acá sola |
| 2 | `swap` | **16 GB** | linux-swap, flag `swap` | swap | ≥ RAM (8 GB) → permite **hibernación** |
| 3 | `root` | **resto (~239 GB)** | ext4 | `/` | Un solo root; sin /home separado |

> Con 8 GB de RAM, 16 GB de swap dan margen para hibernar (la imagen de RAM
> se vuelca al swap) y para picos de compilación/Docker.

### 4.2 Pasos en el instalador

1. Menú de EndeavourOS → **Start the installer** (online, usa Calamares).
2. Idioma, zona horaria, teclado.
3. **Disk configuration → Manually partition** (recomendado):
   * Seleccioná el NVMe de 256 GB → **Delete all** (borra las 2 particiones de Ubuntu)
   * Creá en orden:
     1. New partition → 1 GB → FAT32 → Mount: `/boot/efi` → flags: **boot**
     2. New partition → 16 GB → linux-swap → activar flag **swap**
     3. New partition → resto → ext4 → Mount: `/`
4. **Bootloader:** `systemd-boot` (recomendado, nativo UEFI, simple) — GRUB
   también sirve si lo preferís.
5. **Package selection (Online installer):**
   * Desktop: **Xfce** (marcado)
   * Opcional extra: dejá la lista por defecto; el i3 va después con el dotfile
   * **yay** (AUR helper): marcado (por defecto en EndeavourOS)
6. **Usuario:** creá tu cuenta (no uses "root" como usuario normal).
7. Instalación → reiniciá → sacá el USB.

> **Nota:** en este punto NO instalamos `eos-settings-i3wm` ni `eos-settings-xfce`
> a mano. El dotfile de este repo instala i3 sin chocar con XFCE (ver Fase 7).

---

## Fase 5 — Post-instalación base (antes de apps)

```bash
# 1. Sistema completo actualizado
sudo pacman -Syu

# 2. Herramientas de diagnóstico rápidas
sudo pacman -S --needed base-devel git curl wget

# 3. ThinkPad: brillo por teclado (Fn) y batería
sudo pacman -S --needed brightnessctl tlp
sudo systemctl enable --now tlp
# ThinkPad extras: lectura de temperatura/batería
sudo pacman -S --needed tp_smapi-dkms 2>/dev/null || true
# (thinkpad_acpi ya viene en el kernel; `sensors` con lm_sensors opcional)

# 4. Wi-Fi AX200: el driver iwlwifi ya viene en el kernel. Si no conecta:
sudo pacman -S --needed linux-firmware
# Verificación:
inxi -n && inxi -N

# 5. Bluetooth (Intel, ya soportado)
sudo systemctl enable --now bluetooth

# 6. Audio (PipeWire moderno)
sudo pacman -S --needed pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
```

### 5.1 Hibernación (swap 16 GB)

```bash
# Obtener UUID de la partición swap
sudo blkid /dev/disk/by-uuid/   # o: findmnt -no SOURCE /swap... ; ls -l /dev/disk/by-uuid

# Agregar resume= al kernel
# Editá /etc/default/grub si usás GRUB:
#   GRUB_CMDLINE_LINUX_DEFAULT="... resume=UUID=XXXX-XXXX"
# Con systemd-boot: editá /boot/loader/entries/*.conf y agregá en OPTIONS:
#   resume=UUID=XXXX-XXXX

# Si systemd-boot + Calamares no dejó la entrada, creala:
sudo nano /etc/default/grub   # (si aplica) o el entry de systemd-boot

# Arch wiki recomendado: con partición swap, basta con el parámetro resume.
# Probar:
sudo systemctl hibernate
# → la laptop debe apagar y, al encender de nuevo, restaurar la sesión.
```

Si la hibernación no restaura sesión (pantalla congelada), revisá que el
entry de arranque tenga `resume=UUID=<swap>` y que el swap sea ≥ RAM.

---

## Fase 6 — Primer paso manual: Timeshift (snapshots del sistema)

EndeavourOS es **rolling release**: conviene tener snapshots. Instalalo
**antes** de cargar el sistema con apps:

```bash
sudo pacman -S timeshift

# Configuración inicial (GUI):
timeshift-gui
```

Recomendado para ext4:
* Tipo: **RSYNC**
* Dispositivo: el propio disco (carpeta `/` o partición dedicada; con 239 GB
  usá `/timeshift` o dejá el default y vigilá el espacio)
* Frecuencia: **horario** o **diario** + **mensual**, retener 3-5
* Excluir: `/home` (opcional, tus datos ya tienen backup propio), `/tmp`, `/var/cache`

Primer snapshot a mano:
```bash
sudo timeshift --create --comments "post-instal base antes de apps"
```

Regla: snapshot **antes** de cada `yay -Syu grande** o instalación AUR riesgosa.
Restaurar: boot desde el USB de EndeavourOS → Timeshift → Restore.

---

## Fase 7 — i3wm + XFCE + tus dotfiles (KooL)

XFCE ya quedó instalado en Calamares. Ahora se agrega i3 con TU config:

```bash
# 1. Clonar este repo de dotfiles
git clone https://github.com/lucioamarilla/dotfiles_endeavouros.git ~/dotfiles_endeavouros
cd ~/dotfiles_endeavouros/endeavouros-i3wm-setup-main

# 2. Instalar (paquetes i3 + copia de configs del repo)
./i3_install

# 3. Carpetas que usa el dotfile
mkdir -p ~/Pictures/wallpapers
# copiá tus wallpapers ahí (SUPER+W los lista)

# 4. Cerrar sesión
```

En el display manager (Ly o LightDM de EndeavourOS) elegí sesión **i3**.
Si i3 pregunta por generar config por defecto → **NO** (ya tenés la del repo).

**Conflicto XFCE vs i3 (evitado):** el instalador de este repo NO usa
`eos-settings-i3wm`, por eso no choca con los settings de XFCE que instaló
Calamares. No instales `eos-settings-i3wm` a mano.

Verificación: `SUPER+Return` → kitty · `SUPER+D` → rofi · `SUPER+W` → wallpapers.

---

## Fase 8 — Apps: instalación con install-apps.sh + restauración

### 8.1 El script

```bash
cd ~/dotfiles_endeavouros/endeavouros-i3wm-setup-main
chmod +x install-apps.sh
./install-apps.sh
```

El script instala (~60 apps seleccionadas del cribado):

| Categoría | Apps |
|---|---|
| Terminal/system | zsh+zplug, alacritty, neovim, fastfetch, btop, nvtop, lsd, inxi, smartmontools, rar, unzip, flatpak |
| Medios | vlc, cava, pavucontrol, pamixer, ffmpeg, obs-studio, loupe, okular |
| Documentos | onlyoffice (flatpak), typora (AUR), obsidian (flatpak), pandoc, thunderbird, jopdf (AUR), R, LaTeX parcial |
| Redes/DevOps | docker, gns3 (AUR), packettracer (AUR, .deb manual), ansible, nmap, **wireshark+tshark**, wireguard, traceroute, sshpass, samba, remmina, tigervnc, mactelnet (AUR), macchanger, insomnia (flatpak) |
| Bases de datos | mariadb, mssql-server+mssql-tools (AUR), dbeaver |
| Lenguajes | base-devel, cmake, meson, go, jdk24-openjdk (AUR), maven, nodejs+npm, doxygen, cppcheck, ohcount (AUR), mercurial, ripgrep, flutter |
| IDE/VM | visual-studio-code-bin (AUR), virtualbox |
| Navegación | librewolf (AUR), discord, localsend, protonvpn (flatpak), spotify (AUR), clamav+clamtk |
| IA | opencode (repo oficial) |

**Descartados deliberadamente** (duplicados/sin uso): vim, neofetch, htop,
mpv, grabadores extra (SSR/Kooha), mousepad, libreoffice (→onlyoffice),
qalculate, ganttproject, draw.io, figma, penpot, CAD (librecad/freecad),
inkscape, blender, teamviewer, anydesk, ngrok, IDEs JetBrains/Eclipse/NetBeans,
android-studio, vscode-insiders, chromium, firefox (→librewolf), nuclear,
ollama, lmstudio, chatgpt, entrada china, snaps, Sway/Hyprland stack,
VMware, QEMU/KVM.

### 8.2 Pasos manuales post-script

```bash
# MSSQL (Developer edition, gratis para lab)
sudo /opt/mssql/bin/mssql-conf setup
sudo systemctl enable --now mssql-server
# Cliente: dbeaver → localhost:1433, user sa

# Packet Tracer (una vez tengas el .deb de netacad):
mkdir -p ~/.cache/yay/packettracer
cp ~/Descargas/CiscoPacketTracer_*_Ubuntu_64bit.deb ~/.cache/yay/packettracer/
yay -S packettracer
# Primera ejecución: aceptá la licencia desde terminal:
# /usr/lib/packettracer/packettracer.AppImage

# GNS3: permisos de ubridge si da error
sudo setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge

# R paquetes CRAN
R -e 'install.packages(c("tidyverse","ggplot2","igraph","jsonlite"), repos="https://cran.r-project.org")'

# Cerrá sesión para aplicar grupo docker
```

### 8.3 Restaurar el backup en la nueva EndeavourOS

```bash
# Montar el share de la PC escritorio (misma receta de la Fase 1.5)
sudo mount -t cifs //IP_DESTINO/backup ~/mnt_backup -o username=TU_USUARIO

# Traer datos al home nuevo (excluyendo lo que ya configura el dotfile)
rsync -avh --progress ~/mnt_backup/Facultad ~/     # → ~/Facultad
rsync -avh --progress ~/mnt_backup/Descargas ~/     # → ~/Descargas

# Claves (¡ojo con permisos!)
rsync -avh ~/mnt_backup/.ssh ~/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
rsync -avh ~/mnt_backup/.gnupg ~/ && chmod 700 ~/.gnupg

# Configs que no trae el dotfile i3 (las de Hyprland son referencia en ~/hypr-dots-backup)
mkdir -p ~/hypr-dots-backup
rsync -avh ~/mnt_backup/.config/hypr ~/hypr-dots-backup/
rsync -avh ~/mnt_backup/.config/nvim ~/.config/
rsync -avh ~/mnt_backup/.config/btop ~/.config/
rsync -avh ~/mnt_backup/.config/opencode ~/.config/ 2>/dev/null || true
# kitty: NO sobrescribir sin revisar — el dotfile i3 ya trae kitty.conf compatible
```

Sync de apps:
* **LibreWolf:** Firefox Account (Ajustes → Sync). Si algo no sincroniza,
  LibreWolf es un fork respetuoso con la privacidad — misma cuenta Firefox.
* **VS Code:** Ctrl+Shift+P → *Settings Sync: Turn on*.

### 8.4 Habilitar flatpaks clave (si el script los omitió)

```bash
sudo flatpak install -y --system flathub \
  com.onlyoffice.Desktopeditors md.obsidian.Obsidian \
  rest.insomnia.Insomnia com.protonvpn.www
```

---

## Fase 9 — Lab DevOps/Redes: notas de configuración

### Docker
```bash
sudo systemctl enable --now docker
# usuario en grupo docker ya agregado por el script (re-login)
docker run --rm hello-world
# Portainer u otras UIs: opcionales vía docker compose
```

### GNS3
* Abrí GNS3 → te va a pedir privilegios para el servidor local.
* Preferencias → Server → Local server → *Run as root* solo si hace falta
  para ubridge (ideal: capabilities, no root).
* QEMU lo usa GNS3 internamente si instalás imágenes que lo requieran
  (`sudo pacman -S qemu-system-x86` únicamente cuando GNS3 lo pida).

### Packet Tracer
* Login NetAcad: si el botón Login no abre el navegador, el PKGBUILD actual
  ya incluye el shim de xdg-open. Fallback:
  `XDG_CURRENT_DESKTOP=GNOME QT_QPA_PLATFORM=xcb /usr/lib/packettracer/packettracer.AppImage`
* Las topologías guardadas (.pkt) son portables desde tu Ubuntu anterior.

### MSSQL
```bash
sudo systemctl status mssql-server
sudo journalctl -u mssql-server -f
# Reinicio después de upgrades: convert/formato de BDs es one-way (2022→2025)
```

### MariaDB
```bash
sudo mysql_secure_installation
mysql -u root -p
```

### WireGuard / Macchanger / MikroTik
```bash
# WireGuard: wg-quick con configs en /etc/wireguard/
sudo pacman -S --needed wireguard-tools
# MikroTik sin IP:
mactelnet -l   # listar por MAC
```

---

## Fase 10 — Verificación y troubleshooting L15 Gen 1

### Checklist post-instalación
- [ ] Wi-Fi conecta (AX200 / `iwlwifi`) — `inxi -n`
- [ ] Bluetooth empareja (`bluetoothctl`)
- [ ] Brillo Fn funciona (`brightnessctl`)
- [ ] Audio en altavoces y micrófono (`wpctl status`, pavucontrol)
- [ ] Cámara detectada (`ls /dev/video*`)
- [ ] Suspend (Fn) y **hibernación** restauran sesión
- [ ] `sudo dmidecode -s system-product-name` → ThinkPad L15
- [ ] Docker corre un contenedor
- [ ] GNS3 levanta servidor + ubridge
- [ ] Timeshift tiene al menos 1 snapshot

### Problemas comunes

| Síntoma | Solución |
|---|---|
| Wi-Fi no ve redes | `sudo pacman -Syu linux-firmware`; `sudo dmesg \| grep iwl` |
| Brillo no cambia | `brightnessctl set 50%`; agregar `acpi_backlight=native` al kernel si hace falta |
| Hiberna pero no restaura | Verificar `resume=UUID=<swap>` en el entry de arranque; swap ≥ 8 GB |
| Ventas/teclado raro en i3 | Revisar `~/.config/i3/config`; `SUPER+Shift+K` muestra keybinds |
| `ubridge: permission denied` | `sudo setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge` |
| MSSQL no arranca | `journalctl -u mssql-server`; correr `mssql-conf setup` de nuevo |
| yay pide revisar PKGBUILD | Es AUR: leé el diff; Enter para aceptar |
| Pantalla al despertar congelada | Desactivar hibernación temporalmente; probar suspend clásico |

### Riesgos de Arch (rolling)
* Actualizá seguido: `yay -Syu` (no dejar semanas sin actualizar).
* Antes de actualizaciones grandes: Timeshift snapshot.
* AUR: paquetes de comunidad — revisá el PKGBUILD, especialmente
  `mssql-server`, `packettracer`, `typora`, `jopdf` (usan .deb upstream).
* No hay versiones LTS: si necesitás estabilidad extrema para una entrega,
  snapshot antes y congelá `sudo pacman -Syu` esa semana.

---

## Anexo A — Inventario ThinkPad Ubuntu → EndeavourOS

| Ubuntu (ThinkPad) | EndeavourOS | Fuente |
|---|---|---|
| build-essential | base-devel | pacman |
| docker-ce, containerd.io | docker, docker-compose | pacman |
| gns3-gui, gns3-server, gns3-iou, ubridge | igual nombre | AUR |
| packettracer | packettracer (+.deb manual) | AUR |
| mariadb-server, mariadb-client | mariadb | pacman |
| mssql-server, mssql-tools18 | mssql-server, mssql-tools | AUR |
| ansible, sshpass | ansible, sshpass | pacman |
| nmap, traceroute, wireguard | nmap, traceroute, wireguard-tools | pacman |
| samba | samba | pacman |
| remmina, remmina-plugin-vnc | remmina, remmina-plugins-vnc | pacman |
| tightvncserver | tigervnc | pacman |
| teamviewer, anydesk | — (descartados) | — |
| ngrok | — (descartado) | — |
| macchanger | macchanger | pacman |
| mactelnet-client | mactelnet | AUR |
| wireshark | wireshark, tshark | pacman |
| xfce4, xfce4-goodies | xfce4, xfce4-goodies | pacman |
| i3 stack (instalado por dotfile) | i3-wm… | pacman+AUR (i3_install) |
| alacritty, kitty | alacritty, kitty | pacman |
| zsh, zplug | zsh + zplug | pacman + installer |
| neovim, vim | neovim (vim descartado) | pacman |
| fastfetch, neofetch | fastfetch | pacman |
| btop, htop | btop | pacman |
| nvtop, inxi | nvtop, inxi | pacman |
| lsd, ripgrep | igual | pacman |
| mpv, vlc | vlc | pacman |
| cava, pavucontrol, pamixer, playerctl | igual | pacman |
| ffmpeg | ffmpeg | pacman |
| obs-studio, simplescreenrecorder | obs-studio | pacman |
| loupe, okular, mousepad | loupe, okular | pacman |
| typora | typora | AUR |
| jopdf | jopdf | AUR |
| pandoc | pandoc | pacman |
| thunderbird | thunderbird | pacman |
| libreoffice / onlyoffice | onlyoffice | flatpak |
| r-cran-* | r + install.packages | pacman + CRAN |
| latex | texlive-* parcial + latexmk | pacman |
| golang | go | pacman |
| jdk-24, maven | jdk24-openjdk, maven | AUR + pacman |
| python3, pip, venv | python (base) + python-pip | pacman |
| nodejs | nodejs, npm | pacman |
| cmake, meson, gcc, make | base-devel, cmake, meson | pacman |
| doxygen, cppcheck, ohcount | igual | pacman/AUR |
| mercurial | mercurial | pacman |
| gns3/ubridge, qemu-system | qemu solo si GNS3 lo pide | pacman |
| virtualbox-qt | virtualbox (+host-dkms) | pacman |
| blueman | blueman | pacman |
| brightnessctl, smartmontools, rar, unzip | igual | pacman |
| flatpak, gnome-software-plugin-flatpak | flatpak + flathub | pacman |
| snapd | — (descartado: sin snaps) | — |
| ibus chino, m17n, libpinyin | — (descartado) | — |
| grub-efi, shim-signed | systemd-boot (o GRUB) | instalador EOS |
| ubuntu-* | — | — |
| libreoffice y suites | onlyoffice | flatpak |

## Anexo B — Apps destacadas del escritorio (Ubuntu) → EndeavourOS

| Escritorio | EndeavourOS | Fuente |
|---|---|---|
| visual-studio-code (deb) | visual-studio-code-bin | AUR |
| code-insiders (snap) | — (dup) | — |
| firefox (snap) | librewolf (a elección propia) | AUR |
| chromium (snap) | — (dup) | — |
| discord (snap) | discord | pacman |
| spotify-client | spotify | AUR |
| obs-studio (snap) | obs-studio | pacman |
| onlyoffice (snap) | onlyoffice | flatpak |
| dbeaver (flatpak) | dbeaver | pacman |
| draw.io (flatpak+.deb) | — (dup/descartado) | — |
| figma, penpot | — | — |
| localsend (snap+flatpak) | localsend | pacman |
| protonvpn (flatpak) | protonvpn | flatpak |
| clamtk (deb) / ClamUI | clamav, clamtk | pacman |
| insomnia (flatpak) | insomnia | flatpak |
| obsidian (snap) | obsidian | flatpak |
| thunderbird (snap) | thunderbird | pacman |
| IntelliJ, PyCharm, Eclipse, NetBeans | — (descartados) | — |
| android-studio (snap) | — | — |
| flutter | flutter | AUR |
| virt-manager (flatpak) | — (VirtualBox elegido) | — |
| LM Studio, Ollama | — | — |
| agentes IA (claude, codex, copilot…) | solo opencode | pacman |
| libreoffice (deb) | onlyoffice (elegido) | flatpak |
| ganttproject | — | — |
| librecad, freecad | — | — |
| inkscape, blender | — | — |
| anydesk, teamviewer | — | — |
| MPV (desktop) | vlc (elegido) | pacman |
| typora (ppa) | typora | AUR |
| neovim (ppa) | neovim | pacman |

---

## Créditos y referencias

* Este repo: [endeavouros-i3wm-setup](https://github.com/lucioamarilla/dotfiles_endeavouros) (dotfile i3 estilo KooL Hyprland)
* Base oficial: [endeavouros-team/endeavouros-i3wm-setup](https://github.com/endeavouros-team/endeavouros-i3wm-setup)
* [Arch Wiki — ThinkPad](https://wiki.archlinux.org/title/ThinkPad) · [Hibernate](https://wiki.archlinux.org/title/Hibernation) · [AUR](https://aur.archlinux.org)
* EndeavourOS Wiki: [endeavouros.com/web/wiki](https://wiki.endeavouros.com/)
