#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              ShiraOS — WallpaperSelector                     ║
# ║     Seletor de wallpapers para Hyprland / Arch / CachyOS     ║
# ║            github.com/OshiroAka/Dotfiles                     ║
# ╚══════════════════════════════════════════════════════════════╝
# Uso:  bash install.sh
# Flags:
#   --no-aur       Pula pacotes AUR (quickshell, swww, etc.)
#   --no-hyprland  Não modifica hyprland.conf
#   --no-build     Não compila o plugin C++
#   --update       Atualiza config sem reinstalar dependências

set -euo pipefail
IFS=$'\n\t'

# ── Cores ─────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

step()  { echo -e "\n${CYAN}${BOLD}▸ $1${NC}"; }
ok()    { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "  ${RED}✘${NC}  $1" >&2; }
info()  { echo -e "  ${DIM}$1${NC}"; }
ask()   { echo -e -n "  ${CYAN}?${NC}  $1 "; }

# ── Paths ─────────────────────────────────────────────────────
REPO_URL="https://github.com/OshiroAka/Dotfiles.git"
DOTFILES="$HOME/Dotfiles"
QS_CFG="$HOME/.config/quickshell/shiraos"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/shiraos"
WALL_BASE="$HOME/Pictures/Wallpapers"
SETTINGS_FILE="$QS_CFG/wp_settings.json"

# ── Flags ─────────────────────────────────────────────────────
DO_AUR=true; DO_HYPR=true; DO_BUILD=true; DO_UPDATE=false
for arg in "$@"; do
    case "$arg" in
        --no-aur)       DO_AUR=false ;;
        --no-hyprland)  DO_HYPR=false ;;
        --no-build)     DO_BUILD=false ;;
        --update)       DO_UPDATE=true ;;
    esac
done

# ── Banner ────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
   _____ _     _              ____  ____
  / ___/| |__ (_)_ __ __ _  / __ \/ ___|
  \__ \ | '_ \| | '__/ _` || |  | \___ \
  ___/ || | | | | | | (_| || |__| |___) |
 /____/ |_| |_|_|_|  \__,_| \____/|____/
       WallpaperSelector for Hyprland
EOF
echo -e "${NC}"

# ── Verificações ──────────────────────────────────────────────
step "Verificando ambiente"

if ! command -v pacman &>/dev/null; then
    fail "Este script requer Arch Linux ou CachyOS (pacman não encontrado)"
    exit 1
fi
ok "Arch/CachyOS detectado"

if ! command -v hyprland &>/dev/null && ! pgrep -x Hyprland &>/dev/null; then
    warn "Hyprland não detectado. O WallpaperSelector requer Hyprland."
    ask "Continuar mesmo assim? (s/N)"
    read -r reply
    [[ "$reply" =~ ^[Ss]$ ]] || exit 0
fi

mkdir -p "$CACHE_DIR" "$BIN_DIR" "$HOME/.config/quickshell"

# ── AUR helper ────────────────────────────────────────────────
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if $DO_AUR && [[ -z "$AUR_HELPER" ]]; then
    step "Instalando yay (helper AUR)"
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/yay-install
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    AUR_HELPER="yay"
    ok "yay instalado"
fi

$DO_AUR && ok "AUR helper: $AUR_HELPER"

# ── Dependências pacman ───────────────────────────────────────
if ! $DO_UPDATE; then
    step "Instalando dependências do sistema (pacman)"

    PKGS=(
        # Qt6 (Quickshell)
        qt6-base qt6-declarative qt6-imageformats qt6-multimedia
        # Build
        cmake ninja gcc pkgconf
        # Ferramentas
        git python imagemagick swww
        # Hyprland extras
        xdg-desktop-portal-hyprland
    )

    MISSING=()
    for p in "${PKGS[@]}"; do
        pacman -Qi "$p" &>/dev/null || MISSING+=("$p")
    done

    if [[ ${#MISSING[@]} -gt 0 ]]; then
        info "Instalando: ${MISSING[*]}"
        sudo pacman -S --needed --noconfirm "${MISSING[@]}" || {
            warn "Alguns pacotes falharam, tentando individualmente..."
            for p in "${MISSING[@]}"; do
                sudo pacman -S --needed --noconfirm "$p" 2>/dev/null && ok "$p" || warn "$p não encontrado, pulando"
            done
        }
    fi
    ok "Dependências do sistema prontas"

    # ── Dependências AUR ──────────────────────────────────────
    if $DO_AUR; then
        step "Instalando dependências AUR"

        AUR_PKGS=(quickshell-git)

        # Opcionais — wallpaper engines
        AUR_OPTIONAL=(mpvpaper linux-wallpaperengine)

        for p in "${AUR_PKGS[@]}"; do
            if ! pacman -Qi "$p" &>/dev/null; then
                info "Instalando $p..."
                "$AUR_HELPER" -S --needed --noconfirm "$p" || { fail "Falha ao instalar $p"; exit 1; }
            fi
            ok "$p"
        done

        for p in "${AUR_OPTIONAL[@]}"; do
            if ! pacman -Qi "$p" &>/dev/null; then
                ask "Instalar $p (opcional)? (s/N)"
                read -r r
                if [[ "$r" =~ ^[Ss]$ ]]; then
                    "$AUR_HELPER" -S --needed --noconfirm "$p" && ok "$p" || warn "$p falhou, pulando"
                else
                    warn "$p pulado"
                fi
            else
                ok "$p"
            fi
        done
    fi
fi # !DO_UPDATE

# Verificar Quickshell
if ! command -v qs &>/dev/null; then
    fail "Quickshell (qs) não encontrado. Instale quickshell-git via AUR."
    exit 1
fi
ok "Quickshell: $(qs --version 2>/dev/null | head -1 || echo 'ok')"

# Verificar swww
if ! command -v swww &>/dev/null; then
    warn "swww não encontrado — wallpapers estáticos não funcionarão"
    info "Instale: sudo pacman -S swww"
else
    ok "swww: $(swww --version 2>/dev/null | head -1 || echo 'ok')"
fi

# ── Clonar / atualizar dotfiles ───────────────────────────────
step "Configurando dotfiles ShiraOS"

if [[ -d "$DOTFILES/.git" ]]; then
    info "Dotfiles já existem — atualizando..."
    git -C "$DOTFILES" pull --ff-only 2>/dev/null && ok "Dotfiles atualizados" || warn "git pull falhou, usando versão local"
else
    rm -rf "$DOTFILES"
    git clone "$REPO_URL" "$DOTFILES"
    ok "Dotfiles clonados"
fi

# ── Instalar config do Quickshell ─────────────────────────────
step "Instalando ShiraOS WallpaperSelector"

SRC_QS="$DOTFILES/ShiraShell/quickshell"

if [[ ! -d "$SRC_QS" ]]; then
    fail "Pasta ShiraShell não encontrada nos dotfiles (esperado: $SRC_QS)"
    exit 1
fi

if [[ -d "$QS_CFG" ]] && ! $DO_UPDATE; then
    warn "Já existe uma config em $QS_CFG"
    ask "Sobrescrever? (s/N)"
    read -r r
    if [[ "$r" =~ ^[Ss]$ ]]; then
        # Preserva settings de usuário se existir
        [[ -f "$SETTINGS_FILE" ]] && cp "$SETTINGS_FILE" /tmp/wp_settings_backup.json && info "Settings preservados"
        rm -rf "$QS_CFG"
    else
        info "Mantendo config existente, apenas atualizando arquivos"
        DO_UPDATE=true
    fi
fi

if $DO_UPDATE; then
    # Copia apenas os arquivos do projeto, preserva wp_settings.json
    rsync -a --exclude="wp_settings.json" "$SRC_QS/" "$QS_CFG/"
    [[ -f /tmp/wp_settings_backup.json ]] && mv /tmp/wp_settings_backup.json "$SETTINGS_FILE"
else
    cp -r "$SRC_QS" "$QS_CFG"
    [[ -f /tmp/wp_settings_backup.json ]] && mv /tmp/wp_settings_backup.json "$SETTINGS_FILE"
fi
ok "Config instalada em $QS_CFG"

# ── Compilar plugin C++ ───────────────────────────────────────
if $DO_BUILD && [[ -f "$QS_CFG/CMakeLists.txt" ]]; then
    step "Compilando plugin C++ (ShiraOS)"

    # Detecta QML_DIR
    QML_DIR=""
    for candidate in \
        "/usr/lib/qt6/qml" \
        "/usr/lib64/qt6/qml" \
        "$(qt6-paths --install-prefix 2>/dev/null)/lib/qt6/qml" \
        "$(qtpaths6 --install-prefix 2>/dev/null)/lib/qt6/qml"; do
        [[ -n "$candidate" && -d "$candidate" ]] && { QML_DIR="$candidate"; break; }
    done
    [[ -z "$QML_DIR" ]] && QML_DIR="/usr/lib/qt6/qml"
    info "Módulo QML → $QML_DIR"

    BUILD_DIR="$QS_CFG/build"
    BUILD_LOG="$CACHE_DIR/build.log"
    rm -rf "$BUILD_DIR"; mkdir -p "$BUILD_DIR"

    info "Configurando cmake..."
    cmake -S "$QS_CFG" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQT6_INSTALL_QML="$QML_DIR" \
        -G Ninja > "$BUILD_LOG" 2>&1 || { fail "cmake falhou! Veja: $BUILD_LOG"; tail -20 "$BUILD_LOG"; exit 1; }

    info "Compilando ($(nproc) threads)..."
    ninja -C "$BUILD_DIR" -j"$(nproc)" >> "$BUILD_LOG" 2>&1 || { fail "Build falhou! Veja: $BUILD_LOG"; tail -20 "$BUILD_LOG"; exit 1; }

    info "Instalando módulo..."
    sudo ninja -C "$BUILD_DIR" install >> "$BUILD_LOG" 2>&1 || { fail "Install falhou! Veja: $BUILD_LOG"; exit 1; }

    ok "Plugin ShiraOS compilado → $QML_DIR/ShiraOS"

elif $DO_BUILD; then
    info "CMakeLists.txt não encontrado — plugin C++ não necessário"
fi

# ── Script shiraos ────────────────────────────────────────────
step "Instalando script shiraos"

cat > "$BIN_DIR/shiraos" << 'SCRIPT'
#!/usr/bin/env bash
# ShiraOS WallpaperSelector CLI
CMD="${1:-start}"
case "$CMD" in
    restart|r)
        pkill -x qs 2>/dev/null; sleep 0.25
        qs -c shiraos -d &
        echo "ShiraOS reiniciado."
        ;;
    stop|s)
        pkill -x qs 2>/dev/null && echo "ShiraOS parado." || echo "ShiraOS não estava rodando."
        ;;
    debug|d)
        pkill -x qs 2>/dev/null; sleep 0.1
        qs -c shiraos
        ;;
    ipc)
        shift
        qs -c shiraos ipc call shiraos "$@"
        ;;
    wallpaper|w)
        qs -c shiraos ipc call shiraos toggleWallpaper
        ;;
    start|*)
        if pgrep -x qs &>/dev/null; then
            echo "ShiraOS já está rodando. Use 'shiraos restart' para reiniciar."
        else
            qs -c shiraos -d &
            echo "ShiraOS iniciado."
        fi
        ;;
esac
SCRIPT
chmod +x "$BIN_DIR/shiraos"
ok "shiraos → $BIN_DIR/shiraos"

# ── Diretórios de wallpapers ──────────────────────────────────
step "Criando estrutura de diretórios"
mkdir -p \
    "$WALL_BASE/static" \
    "$WALL_BASE/live" \
    "$WALL_BASE/WallpaperSelector" \
    "$CACHE_DIR"
ok "~/Pictures/Wallpapers/{static,live,WallpaperSelector}"
info "Coloque seus wallpapers estáticos em: ~/Pictures/Wallpapers/static/"
info "Para wallpaper animado (mpvpaper): ~/Pictures/Wallpapers/live/"
info "Para fundo do seletor: ~/Pictures/Wallpapers/WallpaperSelector/"

# ── Hyprland ─────────────────────────────────────────────────
if $DO_HYPR; then
    step "Configurando Hyprland"

    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

    if [[ ! -f "$HYPR_CONF" ]]; then
        warn "hyprland.conf não encontrado em $HYPR_CONF"
        info "Adicione manualmente o bloco abaixo ao seu hyprland.conf:"
    else
        if grep -q "ShiraOS.*WallpaperSelector" "$HYPR_CONF" 2>/dev/null; then
            ok "Hyprland já configurado"
        else
            # Backup
            cp "$HYPR_CONF" "${HYPR_CONF}.bak_shiraos_$(date +%Y%m%d_%H%M%S)"

            cat >> "$HYPR_CONF" << 'HYPR_BLOCK'

# ╔══════════════════════════════════════════════════════════╗
# ║           ShiraOS — WallpaperSelector                    ║
# ╚══════════════════════════════════════════════════════════╝

# Blur + glass no seletor
layerrule = blur,          shiraos-wallpaper
layerrule = ignorealpha 0.05, shiraos-wallpaper

# Atalho: SUPER+W abre o seletor
bind = SUPER, W, exec, shiraos wallpaper

# Iniciar ao login
exec-once = swww-daemon
exec-once = shiraos
HYPR_BLOCK

            ok "Configurações adicionadas ao hyprland.conf"
            info "Backup salvo em ${HYPR_CONF}.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
        fi
    fi
fi

# ── PATH no shell ─────────────────────────────────────────────
step "Verificando PATH"
export PATH="$BIN_DIR:$PATH"

# fish
FISH_CFG="$HOME/.config/fish/config.fish"
if [[ -f "$FISH_CFG" ]] && ! grep -q "local/bin" "$FISH_CFG"; then
    echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CFG"
    ok "fish: ~/.local/bin adicionado"
fi

# bash / zsh
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$RC" ]] && ! grep -q 'local/bin' "$RC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
        ok "$(basename $RC): ~/.local/bin adicionado"
    fi
done
ok "PATH pronto"

# ── Verificação final ──────────────────────────────────────────
step "Verificação final"

CHECKS_OK=true

command -v qs       &>/dev/null && ok "qs (Quickshell)" || { warn "qs não encontrado"; CHECKS_OK=false; }
command -v swww     &>/dev/null && ok "swww"            || warn "swww não encontrado — instale manualmente"
command -v shiraos  &>/dev/null && ok "shiraos CLI"     || { warn "shiraos não no PATH (reinicie o terminal)"; }
[[ -d "$QS_CFG" ]]              && ok "config em $QS_CFG" || { fail "Config não instalada!"; CHECKS_OK=false; }

if [[ -f "$QS_CFG/CMakeLists.txt" ]]; then
    ls /usr/lib/qt6/qml/ShiraOS/qmldir &>/dev/null \
        && ok "Plugin ShiraOS carregado" \
        || { warn "Plugin ShiraOS não encontrado — tente: shiraos debug"; CHECKS_OK=false; }
fi

# ── Resumo ────────────────────────────────────────────────────
echo ""
if $CHECKS_OK; then
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   ShiraOS WallpaperSelector pronto!              ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║   Instalado com avisos — veja acima             ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
fi
echo ""
echo -e "  Iniciar:     ${CYAN}shiraos${NC}"
echo -e "  Reiniciar:   ${CYAN}shiraos restart${NC}"
echo -e "  Debug:       ${CYAN}shiraos debug${NC}"
echo -e "  Abrir painel:${CYAN}SUPER + W${NC}  (ou  shiraos wallpaper)"
echo ""
echo -e "  ${DIM}Coloque wallpapers em ~/Pictures/Wallpapers/static/${NC}"
echo ""
echo -e "  ${YELLOW}⚠  Reinicie o Hyprland para ativar blur e o atalho SUPER+W${NC}"
echo ""
