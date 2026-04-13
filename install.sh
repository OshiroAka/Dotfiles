#!/usr/bin/env bash
# ShiraOS — instalador revisado
# Ajustes principais:
# - set -euo pipefail para falhas reais no build não passarem batido
# - não depende de build/.qt, build/.rcc/qmlcache, .ninja_log ou .ninja_deps
# - log completo do build em ~/.cache/shiraos/build.log
# - cópia mais segura da config

set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
CONFIG_ROOT="$HOME/.config/quickshell"
CONFIG_DIR="$CONFIG_ROOT/shiraos"
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

step "Verificando ambiente"

if ! command -v pacman >/dev/null 2>&1; then
    fail "Este script requer Arch Linux / CachyOS (pacman)"
    exit 1
fi
ok "Arch/CachyOS detectado"

mkdir -p "$CONFIG_ROOT" "$BIN_DIR" "$CACHE_DIR"

# Helper AUR
if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    warn "Nenhum helper AUR encontrado. Instalando yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    (
        cd /tmp/yay-build
        makepkg -si --noconfirm
    )
    ok "yay instalado"
fi

AUR_HELPER="yay"
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
fi
ok "AUR helper: $AUR_HELPER"

step "Instalando dependências do sistema"
PACMAN_DEPS=(
    hyprland
    xdg-desktop-portal-hyprland
    qt6-base
    qt6-base-private
    qt6-declarative
    qt6-declarative-private
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

sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"
ok "Pacotes do sistema instalados"

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

step "Verificando Quickshell"
if ! command -v qs >/dev/null 2>&1; then
    fail "Quickshell (qs) não encontrado após instalação"
    exit 1
fi
ok "Quickshell instalado"

step "Configurando dotfiles ShiraOS"
if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles já existem, atualizando..."
    git -C "$DOTFILES_DIR" pull --ff-only
    ok "Dotfiles atualizados"
else
    git clone "$SHIRAOS_REPO" "$DOTFILES_DIR"
    ok "Dotfiles clonados"
fi

SOURCE_DIR="$DOTFILES_DIR/quickshell/shiraos"
if [ ! -d "$SOURCE_DIR" ]; then
    fail "Pasta quickshell/shiraos não encontrada nos dotfiles"
    exit 1
fi

step "Instalando config do ShiraOS"
if [ -d "$CONFIG_DIR" ]; then
    warn "Config existente encontrada em $CONFIG_DIR"
    read -r -p "  Sobrescrever? (s/N): " REPLY
    if [[ ! "${REPLY:-}" =~ ^[Ss]$ ]]; then
        info "Mantendo config existente"
    else
        rm -rf "$CONFIG_DIR"
    fi
fi

if [ ! -d "$CONFIG_DIR" ]; then
    cp -r "$SOURCE_DIR" "$CONFIG_DIR"
    ok "Config copiada para $CONFIG_DIR"
fi

step "Compilando plugin C++ (ShiraOS)"
if [ ! -f "$CONFIG_DIR/build.sh" ] && [ ! -f "$CONFIG_DIR/CMakeLists.txt" ]; then
    fail "Nem build.sh nem CMakeLists.txt foram encontrados em $CONFIG_DIR"
    exit 1
fi

QML_DIR=""
for d in \
    "/usr/lib/qt6/qml" \
    "/usr/lib64/qt6/qml" \
    "/usr/lib/x86_64-linux-gnu/qt6/qml"; do
    if [ -d "$d" ]; then
        QML_DIR="$d"
        break
    fi
done

if [ -z "$QML_DIR" ] && command -v qtpaths6 >/dev/null 2>&1; then
    PREFIX="$(qtpaths6 --install-prefix 2>/dev/null || true)"
    [ -n "$PREFIX" ] && [ -d "$PREFIX/lib/qt6/qml" ] && QML_DIR="$PREFIX/lib/qt6/qml"
fi
if [ -z "$QML_DIR" ] && command -v qtpaths >/dev/null 2>&1; then
    PREFIX="$(qtpaths --install-prefix 2>/dev/null || true)"
    [ -n "$PREFIX" ] && [ -d "$PREFIX/lib/qt6/qml" ] && QML_DIR="$PREFIX/lib/qt6/qml"
fi

[ -z "$QML_DIR" ] && QML_DIR="/usr/lib/qt6/qml"
info "Instalando módulo QML em: $QML_DIR"

BUILD_DIR="$CONFIG_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
: > "$BUILD_LOG"

(
    cd "$BUILD_DIR"
    cmake "$CONFIG_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQT6_INSTALL_QML="$QML_DIR" \
        -G Ninja
    ninja -j"$(nproc)"
    sudo ninja install
) 2>&1 | tee "$BUILD_LOG"

ok "Plugin compilado e instalado"
info "Log salvo em $BUILD_LOG"

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
        pkill qs 2>/dev/null || true
        sleep 0.3
        qs -c shiraos -d &
        echo "ShiraOS reiniciado."
        ;;
    stop)
        pkill qs 2>/dev/null || true
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
        pkill qs 2>/dev/null || true
        sleep 0.3
        qs -c shiraos -d &
        echo "ShiraOS iniciado."
        ;;
esac
SCRIPT
chmod +x "$BIN_DIR/shiraos"
ok "shiraos"

step "Criando estrutura de diretórios"
mkdir -p "$HOME/Pictures/Wallpapers/static"
mkdir -p "$HOME/Pictures/Wallpapers/live"
mkdir -p "$CACHE_DIR"
ok "Diretórios criados"

step "Configurando Hyprland"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_BLOCK='
# ╔══════════════════════════════════════════════╗
# ║              ShiraOS — Hyprland              ║
# ╚══════════════════════════════════════════════╝

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

bind = SUPER, Super_L, exec, qs -c shiraos ipc call shiraos toggleIsland
bind = SUPER, W, exec, qs -c shiraos ipc call shiraos toggleWallpaper

exec-once = awww-daemon &
exec-once = shiraos
'

if [ -f "$HYPR_CONF" ]; then
    if grep -q "ShiraOS — Hyprland" "$HYPR_CONF"; then
        ok "Hyprland já configurado para o ShiraOS"
    else
        cp "$HYPR_CONF" "$HYPR_CONF.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
        printf '%s\n' "$HYPR_BLOCK" >> "$HYPR_CONF"
        ok "Configurações do ShiraOS adicionadas ao hyprland.conf"
    fi
else
    warn "hyprland.conf não encontrado"
fi

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

step "Configurando Kitty"
mkdir -p "$HOME/.config/kitty"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if grep -q "SHIRASHELL BASIC CONFIG" "$KITTY_CONF" 2>/dev/null; then
    ok "Kitty já configurado"
else
    printf 'background_opacity 0.3\ncursor_trail 10\ncursor_trail_decay 0.3 0.8\n# SHIRASHELL BASIC CONFIG\n' >> "$KITTY_CONF"
    ok "Kitty configurado"
fi

echo
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     ShiraOS instalado com sucesso!       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo
echo -e "  Para iniciar:    ${CYAN}shiraos${NC}"
echo -e "  Para reiniciar:  ${CYAN}shiraos restart${NC}"
echo -e "  Para debug:      ${CYAN}shiraos debug${NC}"
echo -e "  Log do build:    ${CYAN}$BUILD_LOG${NC}"
echo
echo -e "  ${YELLOW}⚠ Reinicie o Hyprland para aplicar as configs!${NC}"
