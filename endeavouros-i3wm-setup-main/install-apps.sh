#!/usr/bin/env bash
# =============================================================================
# install-apps.sh — Instalación masiva de apps para EndeavourOS (Arch)
# Pensado para: ThinkPad L15 Gen 1 (256 GB, 8 GB RAM) — perfil DevOps/Redes
# Selección: cribado app-por-app (ver TUTORIAL_ENDEAVOUROS_THINKPAD_L15.md)
#
# Uso:
#   chmod +x install-apps.sh && ./install-apps.sh
#
# IMPORTANTE:
#   - Ejecutar DESPUÉS de tener `yay` instalado (viene en EndeavourOS).
#   - Revisá los paquetes AUR antes de aceptar (yay muestra el PKGBUILD).
#   - timeshift NO está incluido: instalarlo primero a mano (ver tutorial).
#   - Packet Tracer requiere el .deb manual de Cisco (ver sección 9 del tutorial).
# =============================================================================
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Ejecutá este script como usuario normal (usa sudo interno)."
  exit 1
fi

if ! command -v yay &>/dev/null; then
  echo "yay no está instalado. Instalalo primero: https://wiki.archlinux.org/title/yay"
  exit 1
fi

echo "==> Actualizando sistema completo (pacman + AUR)..."
yay -Syu --noconfirm

# -----------------------------------------------------------------------------
# 1. BASE DEL ENTORNO — XFCE (respaldo) + dependencias de dotfiles i3 (KooL)
#    (i3-wm y los deps se instalan además con ./i3_install del repo de dotfiles;
#     aquí van por si corrés este script antes del dotfile installer)
# -----------------------------------------------------------------------------
echo "==> [1/10] Base: XFCE + deps del dotfile i3..."
sudo pacman -S --needed --noconfirm \
  xfce4 xfce4-goodies \
  i3-wm i3blocks i3lock dunst rofi feh picom kitty thunar thunar-archive-plugin \
  scrot xclip xdotool playerctl polkit-gnome dex xss-lock jq yad imagemagick \
  brightnessctl blueman network-manager-applet \
  xorg-server xorg-xinit

# -----------------------------------------------------------------------------
# 2. TERMINAL, SHELL Y MONITOREO
# -----------------------------------------------------------------------------
echo "==> [2/10] Terminal, shell, editores y monitoreo..."
sudo pacman -S --needed --noconfirm \
  zsh alacritty neovim \
  fastfetch btop nvtop lsd inxi \
  smartmontools htop \
  git ripgrep \
  flatpak unzip zip rar

# zplug (manager de plugins de zsh — lo usabas en Ubuntu)
if [[ ! -d "${ZPLUG_HOME:-$HOME/.zplug}" ]]; then
  echo "==> Instalando zplug..."
  curl -sSL --proto '=https' https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

# Shell por defecto: zsh (opcional, comentá la línea si preferís bash)
# chsh -s "$(command -v zsh)"

# -----------------------------------------------------------------------------
# 3. MEDIOS, AUDIO Y VISORES
# -----------------------------------------------------------------------------
echo "==> [3/10] Medios, audio y visores..."
sudo pacman -S --needed --noconfirm \
  vlc cava pipewire pipewire-pulse pipewire-alsa wireplumber \
  pavucontrol pamixer playerctl \
  ffmpeg obs-studio \
  loupe okular

# -----------------------------------------------------------------------------
# 4. DOCUMENTOS, OFICINA Y NOTAS
# -----------------------------------------------------------------------------
echo "==> [4/10] Documentos, oficina y notas..."
sudo pacman -S --needed --noconfirm \
  thunderbird pandoc \
  texlive-basic texlive-latexextra texlive-fontsrecommended \
  texlive-pictures texlive-bibtexextra texlive-langspanish latexmk

# R (estadística) — paquetes de CRAN se instalan después con install.packages
sudo pacman -S --needed --noconfirm r

# Flatpak: OnlyOffice, Obsidian, Insomnia, DBeaver(GUI extra), ProtonVPN
echo "==> Habilitando Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y --system flathub \
  com.onlyoffice.Desktopeditors \
  md.obsidian.Obsidian \
  rest.insomnia.Insomnia \
  com.protonvpn.www

# AUR: typora (editor markdown), jopdf (editor PDF)
echo "==> [AUR] typora + jopdf (revisá el PKGBUILD cuando yay lo muestre)..."
yay -S --needed --noconfirm typora jopdf

# -----------------------------------------------------------------------------
# 5. REDES Y DevOps — EL NÚCLEO (Docker, GNS3, Packet Tracer, Wireshark…)
# -----------------------------------------------------------------------------
echo "==> [5/10] Redes y DevOps..."
sudo pacman -S --needed --noconfirm \
  docker docker-compose \
  nmap traceroute wireguard-tools sshpass samba \
  wireshark tshark \
  remmina remmina-plugins vnc \
  tigervnc \
  macchanger \
  ansible

# GNS3 (server + gui + ubridge + iou) — AUR
echo "==> [AUR] GNS3 (server, gui, ubridge, iou)..."
yay -S --needed --noconfirm gns3-server gns3-gui ubridge gns3-iou

# MikroTik MAC-Telnet — AUR
echo "==> [AUR] mactelnet (MikroTik)..."
yay -S --needed --noconfirm mactelnet

# Packet Tracer — AUR, requiere el .deb manual de Cisco NetAcad:
#   1) Descargá CiscoPacketTracer_*_Ubuntu_64bit.deb desde https://www.netacad.com/resources/lab-downloads
#   2) Copialo al cache de yay ANTES de instalar:
#        cp ~/Descargas/CiscoPacketTracer_*_Ubuntu_64bit.deb ~/.cache/yay/packettracer/
#   3) yay -S packettracer
#   (ver tutorial sección 9 — fix de login/Qt incluido en el PKGBUILD actual)
echo "AVISO: Packet Tracer NO se instala automáticamente (licencia Cisco)."
echo "       Seguí los 3 pasos de arriba cuando tengas el .deb de NetAcad."

# -----------------------------------------------------------------------------
# 6. BASES DE DATOS — MariaDB + MSSQL Server (nativos, como se decidió)
# -----------------------------------------------------------------------------
echo "==> [6/10] Bases de datos..."
sudo pacman -S --needed --noconfirm mariadb
sudo systemctl enable --now mariadb

# SQL Server 2025 — AUR (setup manual post-instal, ver tutorial sección 9)
echo "==> [AUR] mssql-server + mssql-tools (revisá el PKGBUILD)..."
yay -S --needed --noconfirm mssql-server mssql-tools

# Cliente gráfico multi-DB
sudo pacman -S --needed --noconfirm dbeaver

# -----------------------------------------------------------------------------
# 7. LENGUAJES Y TOOLCHAIN
# -----------------------------------------------------------------------------
echo "==> [7/10] Lenguajes y toolchain..."
sudo pacman -S --needed --noconfirm \
  base-devel cmake meson \
  go maven nodejs npm \
  doxygen cppcheck

# JDK 24 (AUR: package base java24-openjdk, provee jdk24-openjdk)
echo "==> [AUR] JDK 24..."
yay -S --needed --noconfirm jdk24-openjdk

# ohcount (contador de líneas de código) — AUR
yay -S --needed --noconfirm ohcount

# mercurial (VCS hg)
sudo pacman -S --needed --noconfirm mercurial

# -----------------------------------------------------------------------------
# 8. IDE, VIRTUALIZACIÓN Y MÓVIL
# -----------------------------------------------------------------------------
echo "==> [8/10] VS Code, VirtualBox, Flutter..."
yay -S --needed --noconfirm visual-studio-code-bin

sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-dkms
sudo pacman -S --needed --noconfirm linux-headers || true
sudo modprobe vboxdrv || true

# Flutter SDK (AUR) — pesado (~1 GB), quitá la línea si no lo necesitás
yay -S --needed --noconfirm flutter

# -----------------------------------------------------------------------------
# 9. NAVEGACIÓN, COMUNICACIÓN Y SEGURIDAD
# -----------------------------------------------------------------------------
echo "==> [9/10] Navegación, comunicación, VPN, antivirus..."
yay -S --needed --noconfirm librewolf spotify

sudo pacman -S --needed --noconfirm \
  discord localsend clamav clamtk

# LocalSend: se usa el paquete nativo del repo (reemplaza el snap+flatpak dup)

# -----------------------------------------------------------------------------
# 10. IA — solo opencode (agente de código, repo oficial extra)
# -----------------------------------------------------------------------------
echo "==> [10/10] opencode..."
sudo pacman -S --needed --noconfirm opencode

# -----------------------------------------------------------------------------
# POST-INSTALACIÓN — servicios y permisos
# -----------------------------------------------------------------------------
echo "==> Post-instalación: servicios y grupos..."

# Docker: tu usuario en el grupo docker (cerrá y abrí sesión después)
sudo usermod -aG docker "$USER"

# Bluetooth
sudo systemctl enable --now bluetooth.service

# Samba: crear usuario samba para compartir con Windows (opcional)
#   sudo smbpasswd -a "$USER"

# Firewall (EndeavourOS trae ufw opcional; si lo usás:)
#   sudo ufw enable

# -----------------------------------------------------------------------------
# RESUMEN Y SIGUIENTES PASOS MANUALES
# -----------------------------------------------------------------------------
cat <<'EOF'

==============================================================================
 INSTALACIÓN COMPLETADA — pasos manuales pendientes:
==============================================================================
 1) TIMESHIFT (PRIMERO DE TODO si no lo corriste antes de este script):
      sudo pacman -S timeshift
      timeshift --create      # primer snapshot
      (config en el tutorial, sección "Timeshift")
 2) PACKET TRACER: descargá el .deb de Cisco NetAcad y seguí el aviso de la
    sección 5 (yay -S packettracer con el .deb en ~/.cache/yay/packettracer/).
 3) MSSQL:  sudo /opt/mssql/bin/mssql-conf setup   (elegí opción 2 = Developer)
            sudo systemctl enable --now mssql-server
 4) DOCKER: cerrá sesión y volvé a entrar para aplicar el grupo "docker".
    Verificá con:  docker run hello-world
 5) DOTFILES i3: cloná el repo y ejecutá ./i3_install (ver tutorial sección 7).
 6) R paquetes CRAN:
      R -e 'install.packages(c("tidyverse","ggplot2","igraph","jsonlite"),
            repos="https://cran.r-project.org")'
 7) GNS3: si ubridge da "permission denied":
      sudo setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge
 8) RESTAURAR backup: rsync desde tu disco de 2 TB (ver tutorial, Fase 1/8).
 9) FIREFOX→LIBREWOLF: iniciá sesión en Firefox Account para el sync.
10) VSCODE: Settings Sync desde la cuenta Microsoft/GitHub.
==============================================================================
EOF
