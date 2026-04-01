#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           ShiraOS — Script de Instalação             ║
# ║    Quickshell shell para Hyprland/CachyOS/Arch       ║
# ╚══════════════════════════════════════════════════════╝

set -e

DOTFILES_DIR="$HOME/Dotfiles"
CONFIG_DIR="$HOME/.config/quickshell/shiraos"
BIN_DIR="$HOME/.local/bin"
SHIRAOS_REPO="https://github.com/OshiroAka/Dotfiles.git"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}${BOLD}══ $1 ══${NC}"; }
ok()    { echo -e "  ${GREEN}✔${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "  ${RED}✘${NC} $1"; }
info()  { echo -e "  ${NC}•${NC} $1"; }

# ──────────────────────────────────────────────────────
# 0. Verificações iniciais
# ──────────────────────────────────────────────────────
step "Verificando ambiente"

if ! command -v pacman &>/dev/null; then
    fail "Este script requer Arch Linux / CachyOS (pacman)"
    exit 1
fi
ok "Arch/CachyOS detectado"

# Instala yay se não tiver helper AUR
if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    warn "Nenhum helper AUR encontrado. Instalando yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    cd /tmp/yay-build && makepkg -si --noconfirm
    cd "$HOME"
    ok "yay instalado"
fi

AUR_HELPER="yay"
command -v paru &>/dev/null && AUR_HELPER="paru"
ok "AUR helper: $AUR_HELPER"

# ──────────────────────────────────────────────────────
# 1. Dependências do sistema (pacman)
# ──────────────────────────────────────────────────────
step "Instalando dependências do sistema"

PACMAN_DEPS=(
    hyprland
    xdg-desktop-portal-hyprland
    qt6-base
    qt6-declarative
    qt6-imageformats
    qt6-multimedia
    cmake
    ninja
    gcc
    pkgconf
    git
    python
    python-requests
    python-pillow
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    imagemagick
    curl
    jq
    playerctl
    fish
    kitty
    brightnessctl
    btop
    mpv
    grim
    slurp
    swappy
)

sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}" && ok "Pacotes do sistema instalados"

# ──────────────────────────────────────────────────────
# 2. Dependências AUR
# ──────────────────────────────────────────────────────
step "Instalando dependências do AUR"

AUR_DEPS=(
    quickshell-git
    awww                        # wallpaper daemon (substituto do swww)
    linux-wallpaperengine       # wallpapers animados do Steam
    mpvpaper                    # wallpapers de vídeo
    python-colorthief
)

$AUR_HELPER -S --needed --noconfirm "${AUR_DEPS[@]}" && ok "Pacotes AUR instalados"

# ──────────────────────────────────────────────────────
# 3. Verificar Quickshell
# ──────────────────────────────────────────────────────
step "Verificando Quickshell"

if ! command -v qs &>/dev/null; then
    fail "Quickshell (qs) não encontrado após instalação!"
    exit 1
fi
ok "Quickshell instalado"

# ──────────────────────────────────────────────────────
# 4. Clonar/atualizar dotfiles
# ──────────────────────────────────────────────────────
step "Configurando dotfiles ShiraOS"

mkdir -p "$HOME/.config/quickshell"
mkdir -p "$BIN_DIR"

if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles já existem, atualizando..."
    cd "$DOTFILES_DIR" && git pull
    ok "Dotfiles atualizados"
else
    git clone "$SHIRAOS_REPO" "$DOTFILES_DIR"
    ok "Dotfiles clonados"
fi

# ──────────────────────────────────────────────────────
# 5. Instalar config do Quickshell
# ──────────────────────────────────────────────────────
step "Instalando config do ShiraOS"

if [ -d "$DOTFILES_DIR/quickshell/shiraos" ]; then
    if [ -d "$CONFIG_DIR" ]; then
        warn "Config existente encontrada em $CONFIG_DIR"
        read -p "  Sobrescrever? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            rm -rf "$CONFIG_DIR"
        else
            info "Pulando — mantendo config existente"
        fi
    fi

    if [ ! -d "$CONFIG_DIR" ]; then
        cp -r "$DOTFILES_DIR/quickshell/shiraos" "$CONFIG_DIR"
        ok "Config copiada para $CONFIG_DIR"
    fi
else
    warn "Pasta quickshell/shiraos não encontrada nos dotfiles"
fi

# ──────────────────────────────────────────────────────
# 6. Compilar plugin C++
# ──────────────────────────────────────────────────────
step "Compilando plugin C++ (ShiraOS)"

if [ -f "$CONFIG_DIR/build.sh" ]; then
    cd "$CONFIG_DIR"
    bash build.sh && ok "Plugin compilado e instalado"
    cd "$HOME"
else
    warn "build.sh não encontrado"
fi

# ──────────────────────────────────────────────────────
# 7. Instalar scripts ~/.local/bin
# ──────────────────────────────────────────────────────
step "Instalando scripts locais"

# Copia scripts do dotfiles se existirem
if [ -d "$DOTFILES_DIR/modules" ]; then
    for script in shiraos shiraos-weather shiraos-sysinfo shiraos-accent shiraos-lyrics shiraos-lyrics-pos; do
        SRC="$DOTFILES_DIR/modules/$script"
        [ -f "$SRC" ] && cp "$SRC" "$BIN_DIR/$script" && chmod +x "$BIN_DIR/$script" && ok "$script"
    done
fi

# shiraos principal (sempre recria)
cat > "$BIN_DIR/shiraos" << 'SCRIPT'
#!/usr/bin/env bash
case "$1" in
    restart)
        pkill qs 2>/dev/null; sleep 0.3
        qs -c shiraos -d &
        echo "ShiraOS reiniciado."
        ;;
    stop)
        pkill qs 2>/dev/null
        echo "ShiraOS parado."
        ;;
    debug)
        qs -c shiraos 2>&1
        ;;
    ipc)
        shift
        qs -c shiraos ipc call shiraos "$@"
        ;;
    *)
        pkill qs 2>/dev/null; sleep 0.3
        qs -c shiraos -d &
        echo "ShiraOS iniciado."
        ;;
esac
SCRIPT
chmod +x "$BIN_DIR/shiraos"
ok "shiraos"

# ──────────────────────────────────────────────────────
# 8. Criar diretórios necessários
# ──────────────────────────────────────────────────────
step "Criando estrutura de diretórios"

mkdir -p ~/Pictures/Wallpapers/static
mkdir -p ~/Pictures/Wallpapers/live
mkdir -p ~/.cache/shiraos
ok "Diretórios criados"

# ──────────────────────────────────────────────────────
# 9. Configurar Hyprland
# ──────────────────────────────────────────────────────
step "Configurando Hyprland"

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

HYPR_BLOCK='
# ╔══════════════════════════════════════════════╗
# ║              ShiraOS — Hyprland              ║
# ╚══════════════════════════════════════════════╝

# Blur nas camadas do ShiraOS
layerrule = blur on, match:namespace shiraos-island
layerrule = ignore_alpha 0.05, match:namespace shiraos-island
layerrule = blur on, match:namespace shiraos-island-expanded
layerrule = ignore_alpha 0.05, match:namespace shiraos-island-expanded
layerrule = blur on, match:namespace shiraos-wallpaper
layerrule = ignore_alpha 0.05, match:namespace shiraos-wallpaper
layerrule = blur on, match:namespace shiraos-border
layerrule = ignore_alpha 0.05, match:namespace shiraos-border
layerrule = blur on, match:namespace shiraos-scheme
layerrule = ignore_alpha 0.05, match:namespace shiraos-scheme
layerrule = blur on, match:namespace shiraos-config
layerrule = ignore_alpha 0.05, match:namespace shiraos-config
layerrule = blur on, match:namespace shiraos-config-overlay
layerrule = ignore_alpha 0.05, match:namespace shiraos-config-overlay
layerrule = blur on, match:namespace shiraos-panel
layerrule = ignore_alpha 0.05, match:namespace shiraos-panel

# Teclas globais ShiraOS
bind = SUPER, Super_L, exec, qs -c shiraos ipc call shiraos toggleIsland
bind = SUPER, W, exec, qs -c shiraos ipc call shiraos toggleWallpaper

# Iniciar ShiraOS
exec-once = awww-daemon &
exec-once = shiraos
'

if [ ! -f "$HYPR_CONF" ]; then
    warn "hyprland.conf não encontrado"
else
    if grep -q "ShiraOS — Hyprland" "$HYPR_CONF" 2>/dev/null; then
        ok "Hyprland já configurado para o ShiraOS"
    else
        cp "$HYPR_CONF" "$HYPR_CONF.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
        printf '%s\n' "$HYPR_BLOCK" >> "$HYPR_CONF"
        ok "Configurações do ShiraOS adicionadas ao hyprland.conf"
    fi
fi

# ──────────────────────────────────────────────────────
# 10. PATH
# ──────────────────────────────────────────────────────
step "Verificando PATH"

FISH_CONF="$HOME/.config/fish/config.fish"
if [ -f "$FISH_CONF" ]; then
    if ! grep -q "local/bin" "$FISH_CONF"; then
        echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CONF"
        ok "~/.local/bin adicionado ao config.fish"
    else
        ok "config.fish já tem ~/.local/bin"
    fi
fi

export PATH="$BIN_DIR:$PATH"
ok "PATH atualizado"

# ──────────────────────────────────────────────────────
# 11. Resumo final
# ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     ShiraOS instalado com sucesso!       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Para iniciar:    ${CYAN}shiraos${NC}"
echo -e "  Para reiniciar:  ${CYAN}shiraos restart${NC}"
echo -e "  Para debug:      ${CYAN}shiraos debug${NC}"
echo ""
echo -e "  ${YELLOW}⚠ Reinicie o Hyprland para aplicar as configs!${NC}"
echo ""
