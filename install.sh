#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           ShiraOS — Script de Instalação             ║
# ║    Quickshell shell para Hyprland/CachyOS/Arch       ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
CONFIG_DIR="$HOME/.config/quickshell/shiraos"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/shiraos"
BUILD_LOG="$CACHE_DIR/build.log"
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
info()  { echo -e "  • $1"; }

cleanup() {
    cd "$HOME" 2>/dev/null || true
}
trap cleanup EXIT

install_if_available() {
    local available=()
    local missing=()
    local pkg

    for pkg in "$@"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        warn "Pacotes não encontrados no repositório atual: ${missing[*]}"
        warn "Continuando sem eles."
    fi

    if [ ${#available[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${available[@]}"
        ok "Pacotes do sistema instalados"
    else
        warn "Nenhum pacote do sistema válido foi encontrado para instalar"
    fi
}

# ──────────────────────────────────────────────────────
# 0. Verificações iniciais
# ──────────────────────────────────────────────────────
step "Verificando ambiente"

if ! command -v pacman &>/dev/null; then
    fail "Este script requer Arch Linux / CachyOS (pacman)"
    exit 1
fi
ok "Arch/CachyOS detectado"

mkdir -p "$CACHE_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/.config/quickshell"

# Instala yay se não tiver helper AUR
if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    warn "Nenhum helper AUR encontrado. Instalando yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    cd /tmp/yay-build
    makepkg -si --noconfirm
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
    qt6-tools
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

OPTIONAL_PACMAN_DEPS=(
    qt6-base-private
    qt6-declarative-private
)

install_if_available "${PACMAN_DEPS[@]}" "${OPTIONAL_PACMAN_DEPS[@]}"

# ──────────────────────────────────────────────────────
# 2. Dependências AUR
# ──────────────────────────────────────────────────────
step "Instalando dependências do AUR"

AUR_DEPS=(
    quickshell-git
    awww
    linux-wallpaperengine
    mpvpaper
    python-colorthief
)

"$AUR_HELPER" -S --needed --noconfirm "${AUR_DEPS[@]}"
ok "Pacotes AUR instalados"

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

if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles já existem, atualizando..."
    git -C "$DOTFILES_DIR" pull
    ok "Dotfiles atualizados"
else
    rm -rf "$DOTFILES_DIR"
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
        read -r -p "  Sobrescrever? (s/N): " REPLY
        if [[ "$REPLY" =~ ^[Ss]$ ]]; then
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
    fail "Pasta quickshell/shiraos não encontrada nos dotfiles"
    exit 1
fi

# ──────────────────────────────────────────────────────
# 6. Compilar plugin C++
# ──────────────────────────────────────────────────────
step "Compilando plugin C++ (ShiraOS)"

if [ -f "$CONFIG_DIR/build.sh" ] || [ -f "$CONFIG_DIR/CMakeLists.txt" ]; then
    info "Compilando plugin ShiraOS (1-3 min)..."

    QML_DIR=""
    for d in \
        "/usr/lib/qt6/qml" \
        "/usr/lib64/qt6/qml" \
        "/usr/lib/x86_64-linux-gnu/qt6/qml" \
        "$(qtpaths6 --install-prefix 2>/dev/null || true)/lib/qt6/qml" \
        "$(qtpaths --install-prefix 2>/dev/null || true)/lib/qt6/qml"; do
        if [ -n "$d" ] && [ -d "$d" ]; then
            QML_DIR="$d"
            break
        fi
    done

    [ -z "$QML_DIR" ] && QML_DIR="/usr/lib/qt6/qml"
    info "Instalando módulo QML em: $QML_DIR"

    BUILD_DIR="$CONFIG_DIR/build"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    : > "$BUILD_LOG"

    if cmake -S "$CONFIG_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQT6_INSTALL_QML="$QML_DIR" \
        -G Ninja >> "$BUILD_LOG" 2>&1 && \
       ninja -C "$BUILD_DIR" -j"$(nproc)" >> "$BUILD_LOG" 2>&1 && \
       sudo ninja -C "$BUILD_DIR" install >> "$BUILD_LOG" 2>&1; then
        ok "Plugin compilado e instalado em $QML_DIR/ShiraOS"
        info "Log salvo em $BUILD_LOG"
    else
        fail "Build falhou!"
        warn "Log completo: $BUILD_LOG"
        warn "Últimas linhas do erro:"
        tail -n 20 "$BUILD_LOG" || true
        exit 1
    fi
else
    warn "build.sh e CMakeLists.txt não encontrados; pulando build do plugin"
fi

# ──────────────────────────────────────────────────────
# 7. Instalar scripts ~/.local/bin
# ──────────────────────────────────────────────────────
step "Instalando scripts locais"

if [ -d "$DOTFILES_DIR/modules" ]; then
    for script in shiraos shiraos-weather shiraos-sysinfo shiraos-accent shiraos-lyrics shiraos-lyrics-pos; do
        SRC="$DOTFILES_DIR/modules/$script"
        if [ -f "$SRC" ]; then
            cp "$SRC" "$BIN_DIR/$script"
            chmod +x "$BIN_DIR/$script"
            ok "$script"
        fi
    done
fi

cat > "$BIN_DIR/shiraos" <<'SCRIPT'
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
export PATH="$BIN_DIR:$PATH"

# ──────────────────────────────────────────────────────
# 8. Criar diretórios necessários
# ──────────────────────────────────────────────────────
step "Criando estrutura de diretórios"

mkdir -p "$HOME/Pictures/Wallpapers/static"
mkdir -p "$HOME/Pictures/Wallpapers/live"
mkdir -p "$CACHE_DIR"
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
# 11. Configurar Kitty
# ──────────────────────────────────────────────────────
step "Configurando Kitty"
mkdir -p "$HOME/.config/kitty"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if grep -q "SHIRASHELL BASIC CONFIG" "$KITTY_CONF" 2>/dev/null; then
    ok "Kitty já configurado"
else
    printf "background_opacity 0.3\ncursor_trail 10\ncursor_trail_decay 0.3 0.8\n# SHIRASHELL BASIC CONFIG\n" >> "$KITTY_CONF"
    ok "Kitty configurado"
fi

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
