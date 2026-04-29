#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              ShiraOS — WallpaperSelector                    ║
# ║     Seletor de wallpapers para Hyprland / Arch / CachyOS     ║
# ║            github.com/OshiroAka/Dotfiles                     ║
# ╚══════════════════════════════════════════════════════════════╝
# Uso:  bash install.sh
# Flags:
#   --yes         Responde sim para as perguntas principais
#   --no-deps     Pula dependências pacman/AUR
#   --no-aur      Pula pacotes AUR
#   --no-hyprland Não modifica hyprland.conf
#   --no-build    Não compila o plugin C++
#   --update      Atualiza config sem reinstalar dependências

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

ask_yn() {
    local prompt="$1"
    local default="${2:-n}"
    local reply=""

    if [[ "$YES" == true ]]; then
        ok "$prompt: sim (--yes)"
        return 0
    fi

    if [[ "$default" =~ ^[SsYy]$ ]]; then
        ask "$prompt (S/n)"
    else
        ask "$prompt (s/N)"
    fi

    read -r reply || true
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[SsYy]$ ]]
}

# ── Paths ─────────────────────────────────────────────────────
REPO_URL="https://github.com/OshiroAka/Dotfiles.git"
DOTFILES="$HOME/Dotfiles"
QS_CFG="$HOME/.config/quickshell/shiraos"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/shiraos"
WALL_BASE="$HOME/Pictures/Wallpapers"
SETTINGS_FILE="$QS_CFG/wp_settings.json"
WALL_DIRS_FILE="$HOME/.config/shiraos/wallpaper-dirs.txt"

# ── Flags ─────────────────────────────────────────────────────
YES=false
DO_DEPS=true
DO_AUR=true
DO_HYPR=true
DO_BUILD=true
DO_UPDATE=false

for arg in "$@"; do
    case "$arg" in
        --yes|-y)       YES=true ;;
        --no-deps)      DO_DEPS=false ;;
        --no-aur)       DO_AUR=false ;;
        --no-hyprland)  DO_HYPR=false ;;
        --no-build)     DO_BUILD=false ;;
        --update)       DO_UPDATE=true ;;
        *) warn "Flag desconhecida: $arg" ;;
    esac
done

# ── Banner ────────────────────────────────────────────────────
clear || true
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
   _____ _     _              ____  ____
  / ___/| |__ (_)_ __ __ _  / __ \/ ___|
  \__ \ | '_ \| | '__/ _` || |  | \___ \
  ___) || | | | | | | (_| || |__| |___) |
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

if ! command -v Hyprland &>/dev/null && ! command -v hyprland &>/dev/null && ! pgrep -x Hyprland &>/dev/null; then
    warn "Hyprland não detectado. O WallpaperSelector foi feito para Hyprland."
    ask_yn "Continuar mesmo assim?" "n" || exit 0
fi

mkdir -p "$CACHE_DIR" "$BIN_DIR" "$HOME/.config/quickshell" "$HOME/.config/shiraos"

# Evita erro getcwd se o usuário rodar o install de dentro de ~/Dotfiles.
cd "$HOME" # shiraos-safe-cwd

# ── Perguntas principais ──────────────────────────────────────
if [[ "$DO_UPDATE" == true ]]; then
    DO_DEPS=false
    info "Modo --update: dependências serão puladas."
fi

if [[ "$DO_DEPS" == true ]]; then
    ask_yn "Instalar/atualizar dependências do sistema?" "s" || DO_DEPS=false
fi

if [[ "$DO_AUR" == true && "$DO_DEPS" == true ]]; then
    ask_yn "Instalar dependências AUR?" "s" || DO_AUR=false
fi

USE_PYWAL16=false
if [[ "$DO_AUR" == true && "$DO_DEPS" == true ]]; then
    ask_yn "Usar pywal16 via AUR no lugar do pywal normal?" "s" && USE_PYWAL16=true || USE_PYWAL16=false
fi

if [[ "$DO_HYPR" == true ]]; then
    ask_yn "Adicionar bloco do ShiraOS no hyprland.conf?" "s" || DO_HYPR=false
fi

if [[ "$DO_BUILD" == true ]]; then
    ask_yn "Compilar plugin C++ se existir CMakeLists.txt?" "s" || DO_BUILD=false
fi

# ── AUR helper ────────────────────────────────────────────────
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if [[ "$DO_AUR" == true && "$DO_DEPS" == true && -z "$AUR_HELPER" ]]; then
    step "Instalando yay (helper AUR)"
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/yay-install
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    AUR_HELPER="yay"
    ok "yay instalado"
fi

if [[ "$DO_AUR" == true && "$DO_DEPS" == true ]]; then
    ok "AUR helper: ${AUR_HELPER:-nenhum}"
fi

install_pacman_group() {
    local -a pkgs=("$@")
    local -a missing=()

    for pkg in "${pkgs[@]}"; do
        pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "Todos os pacotes pacman do grupo já estão instalados"
        return 0
    fi

    info "Instalando: ${missing[*]}"
    if ! sudo pacman -S --needed --noconfirm "${missing[@]}"; then
        warn "Instalação em grupo falhou. Tentando individualmente..."
        for pkg in "${missing[@]}"; do
            sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null && ok "$pkg" || warn "$pkg não encontrado, pulando"
        done
    fi
}

install_aur_pkg() {
    local pkg="$1"

    if [[ -z "$AUR_HELPER" ]]; then
        warn "Sem AUR helper para instalar $pkg"
        return 0
    fi

    if pacman -Qi "$pkg" &>/dev/null; then
        ok "$pkg já instalado"
        return 0
    fi

    info "Instalando AUR: $pkg"
    "$AUR_HELPER" -S --needed --noconfirm "$pkg" && ok "$pkg" || warn "$pkg falhou — tente manualmente: $AUR_HELPER -S $pkg"
}

# ── Dependências pacman ───────────────────────────────────────
if [[ "$DO_DEPS" == true ]]; then
    step "Instalando dependências do sistema (pacman)"

    # Mantém as dependências antigas e adiciona as atuais usadas pelo ShiraOS.
    PKGS=(
        # Base / build
        base-devel git cmake ninja gcc pkgconf

        # Qt6 / Quickshell
        qt6-base qt6-declarative qt6-imageformats qt6-multimedia qt6-svg qt6-wayland

        # Python / pywal / scripts
        python python-requests python-pillow python-pipx curl jq imagemagick

        # Hyprland / Wayland
        hyprland hyprpaper xdg-desktop-portal xdg-desktop-portal-hyprland
        grim slurp wl-clipboard

        # Wallpaper / media / áudio
        mpv playerctl pipewire pipewire-pulse pipewire-alsa wireplumber

        # Extras úteis para o ecossistema ShiraOS
        cava pavucontrol brightnessctl btop fish kitty
    )

    if [[ "$USE_PYWAL16" == false ]]; then
        PKGS+=(python-pywal)
    fi

    install_pacman_group "${PKGS[@]}"
    ok "Dependências pacman prontas"

    # ── Dependências AUR ──────────────────────────────────────
    if [[ "$DO_AUR" == true ]]; then
        step "Instalando dependências AUR"

        AUR_PKGS=(
            quickshell-git
            awww
            mpvpaper
            linux-wallpaperengine
            python-colorthief
        )

        if [[ "$USE_PYWAL16" == true ]]; then
            AUR_PKGS+=(python-pywal16)
        fi

        for pkg in "${AUR_PKGS[@]}"; do
            install_aur_pkg "$pkg"
        done
    fi
fi

# Verificar Quickshell
if ! command -v qs &>/dev/null; then
    fail "Quickshell (qs) não encontrado. Instale quickshell-git via AUR."
    exit 1
fi
ok "Quickshell: $(qs --version 2>/dev/null | head -1 || echo 'ok')"

if ! command -v awww &>/dev/null; then
    warn "awww não encontrado — instale: yay -S awww"
else
    ok "awww: ok"
fi

if ! command -v wal &>/dev/null; then
    warn "wal/pywal não encontrado — instale python-pywal ou python-pywal16"
else
    ok "pywal/wal: ok"
fi

# ── Clonar / atualizar dotfiles ───────────────────────────────
step "Configurando dotfiles ShiraOS"

if [[ -d "$DOTFILES/.git" ]]; then
    info "Atualizando dotfiles..."
    git -C "$DOTFILES" fetch origin 2>/dev/null \
        && git -C "$DOTFILES" reset --hard origin/main \
        && ok "Dotfiles atualizados" \
        || { warn "git update falhou — reclonando..."; rm -rf "$DOTFILES"; git clone "$REPO_URL" "$DOTFILES" && ok "Dotfiles reclonados"; }
else
    rm -rf "$DOTFILES"
    git clone "$REPO_URL" "$DOTFILES"
    ok "Dotfiles clonados"
fi

# ── Instalar config do Quickshell ─────────────────────────────
step "Instalando ShiraOS WallpaperSelector"

# Detecta a pasta real do ShiraOS dentro do repo.
# Suporta layouts antigos e novos:
#   ShiraShell/shiraos
#   ShiraShell/quickshell/shiraos
#   ShiraShell/quickshell
SRC_QS=""

for candidate in \
    "$DOTFILES/ShiraShell/shiraos" \
    "$DOTFILES/ShiraShell/quickshell/shiraos" \
    "$DOTFILES/ShiraShell/quickshell"
do
    if [[ -f "$candidate/shell.qml" ]]; then
        SRC_QS="$candidate"
        break
    fi
done

if [[ -z "$SRC_QS" ]]; then
    fail "Não achei shell.qml do ShiraOS dentro dos dotfiles."
    info "Procurando shell.qml:"
    find "$DOTFILES" -maxdepth 7 -name shell.qml 2>/dev/null || true
    exit 1
fi

ok "Fonte ShiraOS detectada: $SRC_QS"

if [[ -d "$QS_CFG" && "$DO_UPDATE" == false ]]; then
    warn "Já existe uma config em $QS_CFG"
    if ask_yn "Sobrescrever?" "n"; then
        [[ -f "$SETTINGS_FILE" ]] && cp "$SETTINGS_FILE" /tmp/wp_settings_backup.json && info "Settings preservados"
        rm -rf "$QS_CFG"
    else
        info "Mantendo config existente, apenas atualizando arquivos"
        DO_UPDATE=true
    fi
fi

mkdir -p "$QS_CFG"

if command -v rsync &>/dev/null; then
    if [[ "$DO_UPDATE" == true ]]; then
        rsync -a --exclude="wp_settings.json" "$SRC_QS/." "$QS_CFG/"
    else
        rsync -a "$SRC_QS/." "$QS_CFG/"
    fi
else
    warn "rsync não encontrado; usando cp -r"
    cp -r "$SRC_QS/." "$QS_CFG/"
fi

[[ -f /tmp/wp_settings_backup.json ]] && mv /tmp/wp_settings_backup.json "$SETTINGS_FILE"
ok "Config instalada em $QS_CFG"

# ── Config de diretórios do scanner ───────────────────────────
step "Configurando diretórios de wallpapers"
mkdir -p \
    "$WALL_BASE/static" \
    "$WALL_BASE/live" \
    "$WALL_BASE/WallpaperSelector" \
    "$CACHE_DIR" \
    "$HOME/Downloads"

cat > "$WALL_DIRS_FILE" <<EOF_DIRS
$HOME/Pictures
$HOME/Downloads
$QS_CFG
EOF_DIRS
ok "wallpaper-dirs.txt criado em $WALL_DIRS_FILE"
ok "~/Pictures/Wallpapers/{static,live,WallpaperSelector}"


# ── Fix robusto do qmldir/plugin ShiraOS ─────────────────────
# Resolve casos onde o qmldir aponta para "ShiraOSPluginplugin",
# mas o .so real é "libShiraOSPlugin.so".
check_shiraos_qmldir_plugin() {
    local qml_dir="${1:-}"
    local dest=""
    local plugin=""

    if [[ -z "$qml_dir" ]]; then
        qml_dir="$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)"
        [[ -z "$qml_dir" ]] && qml_dir="/usr/lib/qt6/qml"
    fi

    dest="$qml_dir/ShiraOS"

    [[ -f "$dest/qmldir" ]] || return 1

    plugin="$(awk '$1=="plugin"{print $2; exit}' "$dest/qmldir" 2>/dev/null || true)"
    [[ -n "$plugin" ]] || return 1

    [[ -f "$dest/lib${plugin}.so" ]] || return 1
    return 0
}

fix_shiraos_qmldir_plugin_name() {
    local qml_dir="${1:-}"
    local build_dir="${2:-}"
    local dest=""
    local plugin_file=""
    local plugin_base=""
    local tmp_qmldir=""

    if [[ -z "$qml_dir" ]]; then
        qml_dir="$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)"
        [[ -z "$qml_dir" ]] && qml_dir="/usr/lib/qt6/qml"
    fi

    dest="$qml_dir/ShiraOS"
    sudo install -d "$dest"

    # 1) Procura primeiro um .so já instalado.
    plugin_file="$(find "$dest" -maxdepth 2 -type f \( -name 'libShiraOS*.so' -o -name '*ShiraOS*.so' -o -name 'lib*.so' \) 2>/dev/null | head -n 1 || true)"

    # 2) Se não achou no destino, procura em possíveis diretórios de build.
    if [[ -z "$plugin_file" ]]; then
        for maybe_build in             "$build_dir"             "${QS_CFG:-}/build"             "${SRC_QS:-}/build"             "${DOTFILES:-$HOME/Dotfiles}/ShiraShell/shiraos/build"             "${DOTFILES:-$HOME/Dotfiles}/ShiraShell/quickshell/build"             "$HOME/Dotfiles/ShiraShell/shiraos/build"             "$HOME/Dotfiles/ShiraShell/quickshell/build"
        do
            [[ -n "$maybe_build" && -d "$maybe_build" ]] || continue

            plugin_file="$(find "$maybe_build" -type f \( -name 'libShiraOS*.so' -o -name '*ShiraOS*.so' -o -name 'lib*plugin*.so' \) 2>/dev/null | head -n 1 || true)"
            [[ -n "$plugin_file" ]] && break
        done
    fi

    if [[ -z "$plugin_file" ]]; then
        fail "Não achei o arquivo .so do plugin ShiraOS para corrigir o qmldir."
        info "Procure manualmente com:"
        info "  find ~/Dotfiles ~/.config/quickshell -name '*ShiraOS*.so' -o -name 'lib*plugin*.so'"
        return 1
    fi

    # 3) Garante que o .so está dentro do diretório de módulo QML.
    if [[ "$plugin_file" != "$dest/"* ]]; then
        sudo cp -f "$plugin_file" "$dest/"
        sudo chmod 755 "$dest/$(basename "$plugin_file")"
        plugin_file="$dest/$(basename "$plugin_file")"
    fi

    plugin_base="$(basename "$plugin_file")"
    plugin_base="${plugin_base#lib}"
    plugin_base="${plugin_base%.so}"

    # 4) Recria qmldir usando o nome REAL do .so.
    # Ex:
    #   libShiraOSPlugin.so -> plugin ShiraOSPlugin
    # Isso evita o erro:
    #   module "ShiraOS" plugin "ShiraOSPluginplugin" not found
    tmp_qmldir="$(mktemp)"
    cat > "$tmp_qmldir" <<EOF_QMLDIR
module ShiraOS
plugin $plugin_base
EOF_QMLDIR

    sudo cp "$tmp_qmldir" "$dest/qmldir"
    rm -f "$tmp_qmldir"

    sudo chmod 644 "$dest/qmldir"
    sudo chmod 755 "$dest" 2>/dev/null || true

    if check_shiraos_qmldir_plugin "$qml_dir"; then
        ok "qmldir corrigido: plugin $plugin_base"
        info "Módulo: $dest"
        return 0
    fi

    fail "qmldir foi escrito, mas o plugin ainda não validou."
    info "Conteúdo de $dest:"
    ls -la "$dest" 2>/dev/null || true
    info "qmldir:"
    cat "$dest/qmldir" 2>/dev/null || true
    return 1
}

# ── Compilar / instalar módulo QML ShiraOS ─────────────────────
# Necessário quando shell.qml tem: import ShiraOS
#
# Correção importante:
# O projeto pode compilar, mas o CMake nem sempre instala automaticamente
# /usr/lib/qt6/qml/ShiraOS/qmldir. Quando isso acontece, o Quickshell falha com:
#   module "ShiraOS" is not installed
#
# Então este bloco:
#   1. detecta o QML install dir real do Qt;
#   2. compila o módulo;
#   3. tenta ninja install;
#   4. se o qmldir não aparecer, instala manualmente os artefatos do build.
step "Instalando módulo QML ShiraOS"

detect_qml_dir() {
    local candidate=""

    for candidate in \
        "$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)" \
        "$(qt6-paths --qt-query QT_INSTALL_QML 2>/dev/null || true)" \
        "/usr/lib/qt6/qml" \
        "/usr/lib64/qt6/qml" \
        "$(qtpaths6 --query QT_INSTALL_PREFIX 2>/dev/null || true)/lib/qt6/qml" \
        "$(qt6-paths --install-prefix 2>/dev/null || true)/lib/qt6/qml"
    do
        [[ -n "$candidate" && "$candidate" != "/lib/qt6/qml" && -d "$candidate" ]] && {
            echo "$candidate"
            return 0
        }
    done

    echo "/usr/lib/qt6/qml"
}

find_plugin_source() {
    local candidate=""

    for candidate in \
        "$QS_CFG" \
        "$SRC_QS" \
        "$DOTFILES/ShiraShell/shiraos" \
        "$DOTFILES/ShiraShell/quickshell/shiraos" \
        "$DOTFILES/ShiraShell/quickshell"
    do
        [[ -f "$candidate/CMakeLists.txt" ]] && {
            echo "$candidate"
            return 0
        }
    done

    return 1
}

install_qml_module_manually() {
    local src="$1"
    local build_dir="$2"
    local qml_dir="$3"
    local log="$4"

    local dest="$qml_dir/ShiraOS"
    local stage="$CACHE_DIR/ShiraOS-module-stage"
    local qmldir_file=""
    local plugin_file=""
    local plugin_base=""

    rm -rf "$stage"
    mkdir -p "$stage"

    # 1) Acha o .so do plugin. O nome pode variar:
    #    Não reaproveitamos qmldir gerado pelo CMake porque ele pode
    #    apontar para ShiraOSPluginplugin em vez do .so real.
    #    libShiraOSPlugin.so, libShiraOSPluginplugin.so, etc.
    plugin_file="$(find "$build_dir" -type f \( -name '*ShiraOS*.so' -o -name 'lib*plugin*.so' \) 2>/dev/null | head -n 1 || true)"

    if [[ -z "$plugin_file" ]]; then
        fail "Não achei o .so do plugin ShiraOS no build."
        info "Build dir: $build_dir"
        info "Log: $log"
        find "$build_dir" -maxdepth 5 -type f 2>/dev/null | sed 's/^/  /' | head -80
        return 1
    fi

    cp "$plugin_file" "$stage/"

    plugin_base="$(basename "$plugin_file")"
    plugin_base="${plugin_base#lib}"
    plugin_base="${plugin_base%.so}"

    # 3) Sempre cria qmldir usando o nome REAL do .so encontrado.
    cat > "$stage/qmldir" <<EOF_QMLDIR
module ShiraOS
plugin $plugin_base
EOF_QMLDIR

    # 4) Copia qmltypes/metainfo se existirem.
    find "$build_dir" -type f \( -name '*.qmltypes' -o -name 'plugins.qmltypes' -o -name '*.qmltypes.json' \) -exec cp -f {} "$stage/" \; 2>/dev/null || true

    # 5) Instala módulos QML do projeto, se existirem.
    if [[ -d "$src/modules" ]]; then
        mkdir -p "$stage/modules"
        cp -a "$src/modules/." "$stage/modules/"
    fi

    # 6) Instala em /usr/lib/qt6/qml/ShiraOS ou equivalente.
    sudo rm -rf "$dest"
    sudo install -d "$dest"
    sudo cp -a "$stage/." "$dest/"

    # 7) Permissões seguras.
    sudo find "$dest" -type d -exec chmod 755 {} \;
    sudo find "$dest" -type f -exec chmod 644 {} \;
    sudo find "$dest" -type f -name '*.so' -exec chmod 755 {} \;

    [[ -f "$dest/qmldir" ]]
}

build_and_install_shiraos_module() {
    local plugin_src="$1"
    local qml_dir="$2"
    local build_dir="$plugin_src/build"
    local build_log="$CACHE_DIR/build-shiraos-module.log"

    info "Fonte do módulo: $plugin_src"
    info "QML dir: $qml_dir"
    info "Log: $build_log"

    rm -rf "$build_dir"
    mkdir -p "$build_dir" "$CACHE_DIR" "$qml_dir" 2>/dev/null || true

    cmake -S "$plugin_src" -B "$build_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQT6_INSTALL_QML="$qml_dir" \
        -DQT_QML_OUTPUT_DIRECTORY="$build_dir/qml" \
        -G Ninja > "$build_log" 2>&1 || {
            fail "cmake falhou. Veja: $build_log"
            tail -60 "$build_log"
            return 1
        }

    ninja -C "$build_dir" -j"$(nproc)" >> "$build_log" 2>&1 || {
        fail "Build falhou. Veja: $build_log"
        tail -60 "$build_log"
        return 1
    }

    # O install do CMake pode funcionar em alguns layouts, então tentamos.
    # Mas não confiamos somente nele.
    sudo ninja -C "$build_dir" install >> "$build_log" 2>&1 || {
    fix_shiraos_qmldir_plugin_name "$qml_dir" "$build_dir" || true
        warn "ninja install falhou ou não instalou tudo. Vou tentar instalação manual."
    }

    fix_shiraos_qmldir_plugin_name "$qml_dir" "$build_dir" || true

    if check_shiraos_qmldir_plugin "$qml_dir"; then
        ok "Módulo ShiraOS instalado via CMake: $qml_dir/ShiraOS"
        return 0
    fi

    warn "qmldir não apareceu ou plugin inválido após ninja install; instalando manualmente..."
    install_qml_module_manually "$plugin_src" "$build_dir" "$qml_dir" "$build_log" || return 1

    fix_shiraos_qmldir_plugin_name "$qml_dir" "$build_dir" || true

    if check_shiraos_qmldir_plugin "$qml_dir"; then
        ok "Módulo ShiraOS instalado manualmente: $qml_dir/ShiraOS"
        return 0
    fi

    fail "Mesmo após instalação manual, $qml_dir/ShiraOS/qmldir não apareceu."
    return 1
}

QML_DIR="$(detect_qml_dir)"

if grep -q "import ShiraOS" "$QS_CFG/shell.qml" 2>/dev/null; then
    PLUGIN_SRC="$(find_plugin_source || true)"

    if [[ -z "$PLUGIN_SRC" ]]; then
        fail "shell.qml usa import ShiraOS, mas não achei CMakeLists.txt para compilar o módulo."
        info "Debug:"
        info "  find ~/Dotfiles ~/.config/quickshell -maxdepth 7 -name CMakeLists.txt"
        exit 1
    fi

    build_and_install_shiraos_module "$PLUGIN_SRC" "$QML_DIR" || exit 1

    # Correção opcional: remove caminhos hardcoded do seu usuário nos QML/scripts instalados.
    grep -RIlE '/home/(shira|oshiro|harunelinux)' "$QS_CFG" 2>/dev/null \
        | xargs -r sed -i "s#/home/shira#$HOME#g; s#/home/oshiro#$HOME#g; s#/home/harunelinux#$HOME#g" || true

    if [[ -f "$QML_DIR/ShiraOS/qmldir" ]]; then
        ok "Verificação final do módulo: $QML_DIR/ShiraOS/qmldir"
    else
        fail "Verificação final falhou: $QML_DIR/ShiraOS/qmldir não existe"
        exit 1
    fi
else
    info "shell.qml não usa import ShiraOS — módulo não necessário"
fi


# ── Script shiraos ────────────────────────────────────────────
step "Instalando script shiraos"

cat > "$BIN_DIR/shiraos" << 'SCRIPT'
#!/usr/bin/env bash
CMD="${1:-start}"
CFG="$HOME/.config/quickshell/shiraos"

if [[ ! -f "$CFG/shell.qml" ]]; then
    echo "Config não encontrada em: $CFG/shell.qml"
    find "$HOME/.config/quickshell" -maxdepth 4 -name shell.qml 2>/dev/null || true
    exit 1
fi

case "$CMD" in
    restart|r)
        pkill -x qs 2>/dev/null || true
        sleep 0.25
        qs -c "$CFG" -d &
        echo "ShiraOS reiniciado."
        ;;
    stop|s)
        pkill -x qs 2>/dev/null && echo "ShiraOS parado." || echo "ShiraOS não estava rodando."
        ;;
    debug|d)
        pkill -x qs 2>/dev/null || true
        sleep 0.1
        qs -c "$CFG"
        ;;
    ipc)
        shift
        qs -c "$CFG" ipc call shiraos "$@"
        ;;
    wallpaper|w)
        qs -c "$CFG" ipc call shiraos toggleWallpaper
        ;;
    start|*)
        if pgrep -x qs &>/dev/null; then
            echo "ShiraOS já está rodando. Use 'shiraos restart' para reiniciar."
        else
            qs -c "$CFG" -d &
            echo "ShiraOS iniciado."
        fi
        ;;
esac
SCRIPT
chmod +x "$BIN_DIR/shiraos"
ok "shiraos → $BIN_DIR/shiraos"

# ── Hyprland ─────────────────────────────────────────────────
if [[ "$DO_HYPR" == true ]]; then
    step "Configurando Hyprland"

    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

    if [[ ! -f "$HYPR_CONF" ]]; then
        warn "hyprland.conf não encontrado em $HYPR_CONF"
        info "Adicione manualmente o bloco do ShiraOS ao seu hyprland.conf."
    elif grep -q "ShiraOS.*WallpaperSelector" "$HYPR_CONF" 2>/dev/null; then
        ok "Hyprland já configurado"
    else
        HYPR_BAK="${HYPR_CONF}.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
        cp "$HYPR_CONF" "$HYPR_BAK"

        cat >> "$HYPR_CONF" << 'HYPR_BLOCK'

# ╔══════════════════════════════════════════════════════════╗
# ║           ShiraOS — WallpaperSelector                    ║
# ╚══════════════════════════════════════════════════════════╝

# Blur + glass no seletor/settings
layerrule = blur, shiraos-wallpaper
layerrule = ignorealpha 0.18, shiraos-wallpaper

# Compatibilidade alternativa, caso sua versão do Hyprland use match:
layerrule = blur, match:namespace shiraos-wallpaper
layerrule = ignorealpha 0.18, match:namespace shiraos-wallpaper

# Atalho: SUPER+W abre o seletor
bind = SUPER, W, exec, shiraos wallpaper

# Iniciar ao login
exec-once = awww-daemon
exec-once = shiraos
HYPR_BLOCK

        ok "Configurações adicionadas ao hyprland.conf"
        info "Backup salvo em $HYPR_BAK"
    fi
fi

# ── PATH no shell ─────────────────────────────────────────────
step "Verificando PATH"
export PATH="$BIN_DIR:$PATH"

FISH_CFG="$HOME/.config/fish/config.fish"
if [[ -f "$FISH_CFG" ]] && ! grep -q "fish_add_path.*local/bin" "$FISH_CFG"; then
    echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CFG"
    ok "fish: ~/.local/bin adicionado"
fi

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$RC" ]] && ! grep -q 'HOME/.local/bin' "$RC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
        ok "$(basename "$RC"): ~/.local/bin adicionado"
    fi
done
ok "PATH pronto"

# ── Verificação final ──────────────────────────────────────────
step "Verificação final"

CHECKS_OK=true

command -v qs          &>/dev/null && ok "qs (Quickshell)" || { warn "qs não encontrado"; CHECKS_OK=false; }
command -v awww        &>/dev/null && ok "awww"             || warn "awww não encontrado — yay -S awww"
command -v wal         &>/dev/null && ok "wal/pywal"        || warn "wal não encontrado — python-pywal/python-pywal16"
command -v mpvpaper    &>/dev/null && ok "mpvpaper"         || warn "mpvpaper não encontrado"
command -v playerctl   &>/dev/null && ok "playerctl"        || warn "playerctl não encontrado"
command -v shiraos     &>/dev/null && ok "shiraos CLI"      || warn "shiraos não no PATH; reinicie o terminal"
[[ -d "$QS_CFG" ]]                 && ok "config em $QS_CFG" || { fail "Config não instalada!"; CHECKS_OK=false; }

if [[ -f "$QS_CFG/CMakeLists.txt" ]]; then
    ls /usr/lib/qt6/qml/ShiraOS/qmldir &>/dev/null \
        && ok "Plugin ShiraOS carregado" \
        || warn "Plugin ShiraOS não encontrado — se necessário rode com build ativado"
fi

# ── Resumo ────────────────────────────────────────────────────
echo ""
if [[ "$CHECKS_OK" == true ]]; then
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"

# ── Caelestia pywal scheme slot ─────────────────────────────
# Prepara o slot do Caelestia para o usuário conseguir escrever nele.
# Isso evita pedir sudo toda hora quando o auto scheme/pywal atualizar o tema.
step "Preparando slot Caelestia para pywal"

install_caelestia_pywal_helper_if_found() {
    local helper_name="shiraos-caelestia-pywal-scheme"
    local dest="${BIN_DIR:-$HOME/.local/bin}/$helper_name"
    local dotfiles="${DOTFILES:-$HOME/Dotfiles}"
    local src=""

    mkdir -p "${BIN_DIR:-$HOME/.local/bin}"

    # Se já existe, só garante permissão.
    if [[ -f "$dest" ]]; then
        chmod 755 "$dest" 2>/dev/null || true
        return 0
    fi

    # Tenta achar o helper em locais comuns do repo.
    for src in \
        "$dotfiles/$helper_name" \
        "$dotfiles/.local/bin/$helper_name" \
        "$dotfiles/bin/$helper_name" \
        "$dotfiles/scripts/$helper_name" \
        "$dotfiles/ShiraShell/$helper_name" \
        "$dotfiles/ShiraShell/bin/$helper_name" \
        "$dotfiles/ShiraShell/scripts/$helper_name" \
        "$dotfiles/ShiraShell/shiraos/scripts/$helper_name" \
        "$dotfiles/ShiraShell/quickshell/scripts/$helper_name" \
        "${QS_CFG:-$HOME/.config/quickshell/shiraos}/scripts/$helper_name"
    do
        if [[ -f "$src" ]]; then
            install -m 755 "$src" "$dest"
            return 0
        fi
    done

    return 1
}

prepare_caelestia_pywal_slot() {
    local helper="${BIN_DIR:-$HOME/.local/bin}/shiraos-caelestia-pywal-scheme"
    local status_output=""

    install_caelestia_pywal_helper_if_found || true

    if [[ ! -x "$helper" ]]; then
        warn "Helper não encontrado: $helper"
        warn "Pulando Caelestia pywal slot. Se você usa Caelestia, adicione esse helper ao repo."
        return 0
    fi

    info "Rodando prepare/apply do Caelestia pywal scheme..."
    "$helper" --prepare --apply --allow-sudo --force --no-terminal --attempts 3 || {
        warn "Falha ao preparar/aplicar o scheme do Caelestia."
        warn "Você pode rodar manualmente:"
        warn "  $helper --prepare --apply --allow-sudo --force --no-terminal --attempts 3"
        return 0
    }

    status_output="$("$helper" --status 2>/dev/null || true)"
    if [[ -n "$status_output" ]]; then
        echo "$status_output" | sed 's/^/  /'
    fi

    if echo "$status_output" | grep -q "Writable slot: True"; then
        ok "Caelestia pywal slot preparado: Writable slot: True"
    else
        warn "Não consegui confirmar 'Writable slot: True'. Confira com:"
        warn "  $helper --status"
    fi
}

prepare_caelestia_pywal_slot

    echo -e "${GREEN}${BOLD}║   ShiraOS WallpaperSelector pronto!             ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║   Instalado com avisos — veja acima             ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "  Iniciar:       ${CYAN}shiraos${NC}"
echo -e "  Reiniciar:     ${CYAN}shiraos restart${NC}"
echo -e "  Debug:         ${CYAN}shiraos debug${NC}"
echo -e "  Abrir painel:  ${CYAN}SUPER + W${NC}  ou  ${CYAN}shiraos wallpaper${NC}"
echo ""
echo -e "  ${DIM}Wallpapers estáticos: ~/Pictures/Wallpapers/static/${NC}"
echo -e "  ${DIM}Wallpapers live:     ~/Pictures/Wallpapers/live/${NC}"
echo ""
echo -e "  ${YELLOW}⚠ Reinicie o Hyprland ou rode hyprctl reload para ativar blur/atalho.${NC}"
echo ""
