#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           ShiraOS — Script de Instalação             ║
# ║    Quickshell shell para Hyprland/CachyOS/Arch       ║
# ╚══════════════════════════════════════════════════════╝

set -e

DOTFILES_DIR="$HOME/Dotfiles"
CONFIG_DIR="$HOME/.config/quickshell/shiraos"
BIN_DIR="$HOME/.local/bin"
SHIRAOS_REPO="https://github.com/OshiroAka/Dotfiles.git"   # <-- mude se necessário

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

if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    warn "Nenhum helper AUR encontrado. Instalando paru..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    cd /tmp/paru-build && makepkg -si --noconfirm
    cd "$HOME"
    ok "paru instalado"
fi

AUR_HELPER="paru"
command -v paru &>/dev/null || AUR_HELPER="yay"
ok "AUR helper: $AUR_HELPER"

# ──────────────────────────────────────────────────────
# 1. Dependências do sistema (pacman)
# ──────────────────────────────────────────────────────
step "Instalando dependências do sistema"

PACMAN_DEPS=(
    # Ambiente Wayland / Hyprland
    hyprland
    hyprpaper
    xdg-desktop-portal-hyprland

    # Build Qt6 / C++
    qt6-base
    qt6-declarative
    qt6-imageformats
    qt6-multimedia
    cmake
    ninja
    gcc
    pkgconf
    git

    # Python
    python
    python-requests
    python-pillow

    # Áudio
    pipewire
    pipewire-pulse
    wireplumber
    cava
    pavucontrol

    # Wallpaper
    swww
    mpv

    # Utilitários
    imagemagick
    curl
    jq
    playerctl
    fish
    kitty
    brightnessctl
    btop
)

sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}" && ok "Pacotes do sistema instalados"

# ──────────────────────────────────────────────────────
# 2. Dependências AUR
# ──────────────────────────────────────────────────────
step "Instalando dependências do AUR"

AUR_DEPS=(
    quickshell-git          # framework QML shell
    python-colorthief       # cor adaptativa do wallpaper
)

$AUR_HELPER -S --needed --noconfirm "${AUR_DEPS[@]}" && ok "Pacotes AUR instalados"

# ──────────────────────────────────────────────────────
# 3. Verificar Quickshell
# ──────────────────────────────────────────────────────
step "Verificando Quickshell"

if ! command -v qs &>/dev/null; then
    fail "Quickshell (qs) não encontrado após instalação!"
    info "Tente instalar manualmente: $AUR_HELPER -S quickshell-git"
    exit 1
fi
ok "Quickshell $(qs --version 2>/dev/null | head -1)"

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
    info "Clonando dotfiles de $SHIRAOS_REPO..."
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
    warn "Estrutura esperada: $DOTFILES_DIR/quickshell/shiraos/"
fi

# ──────────────────────────────────────────────────────
# 6. Instalar scripts ~/.local/bin
# ──────────────────────────────────────────────────────
step "Instalando scripts locais"

# shiraos — executável principal
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
        pkill qs 2>/dev/null
        sleep 0.3
        qs -c shiraos -d &
        echo "ShiraOS iniciado."
        ;;
esac
SCRIPT
chmod +x "$BIN_DIR/shiraos"
ok "shiraos"

# shiraos-weather — clima via wttr.in
cat > "$BIN_DIR/shiraos-weather" << 'SCRIPT'
#!/usr/bin/env python3
import subprocess, json, sys, os

# Localização automática — altere se necessário
LOCATION = ""  # Deixe vazio para auto-detectar pela IP

def get_weather():
    url = f"https://wttr.in/{LOCATION}?format=j1"
    try:
        result = subprocess.run(
            ["curl", "-s", "--max-time", "8", url],
            capture_output=True, text=True
        )
        data = json.loads(result.stdout)
    except Exception as e:
        print(f"ERROR:{e}", file=sys.stderr)
        return

    current = data["current_condition"][0]
    area    = data["nearest_area"][0]
    region  = area["areaName"][0]["value"]

    temp    = current["temp_C"]
    desc    = current["weatherDesc"][0]["value"]

    print(f"REGION:{region}")
    print(f"NOW:{temp}|{desc}")

    # Previsão diária (7 dias)
    days_pt = ["Dom","Seg","Ter","Qua","Qui","Sex","Sab"]
    import datetime
    for i, day in enumerate(data["weather"][:7]):
        dt = datetime.date.fromisoformat(day["date"])
        d  = days_pt[dt.weekday() if dt.weekday() != 6 else 6]
        d  = days_pt[(dt.weekday()+1) % 7]
        mn = day["mintempC"]
        mx = day["maxtempC"]
        dc = day["hourly"][4]["weatherDesc"][0]["value"]
        ch = day["hourly"][4]["chanceofrain"]
        print(f"DAY:{d}|{mn}|{mx}|{dc}|{ch}")

    # Previsão horária
    for day in data["weather"][:2]:
        for hour in day["hourly"]:
            t  = hour["time"].zfill(4)
            hh = t[:2] if len(t)==4 else "0"+t[0]
            hh = str(int(hour["time"])//100).zfill(2)
            dt = day["date"]
            tp = hour["tempC"]
            dc = hour["weatherDesc"][0]["value"]
            ch = hour["chanceofrain"]
            print(f"HOUR:{dt}|{hh}:00|{tp}|{dc}|{ch}")

get_weather()
SCRIPT
chmod +x "$BIN_DIR/shiraos-weather"
ok "shiraos-weather"

# shiraos-sysinfo — CPU, RAM, Disco
cat > "$BIN_DIR/shiraos-sysinfo" << 'SCRIPT'
#!/usr/bin/env python3
import os, subprocess

# CPU
with open("/proc/stat") as f:
    line = f.readline().split()
idle1 = int(line[4])
total1 = sum(int(x) for x in line[1:])

import time; time.sleep(0.2)

with open("/proc/stat") as f:
    line = f.readline().split()
idle2 = int(line[4])
total2 = sum(int(x) for x in line[1:])

cpu = round(100 * (1 - (idle2 - idle1) / (total2 - total1)))

# RAM
with open("/proc/meminfo") as f:
    mem = {}
    for line in f:
        k, v = line.split(":")
        mem[k.strip()] = int(v.strip().split()[0])

ram_total = mem["MemTotal"] // 1024
ram_used  = (mem["MemTotal"] - mem["MemAvailable"]) // 1024
ram_pct   = round(100 * ram_used / ram_total)

# Disco
st = os.statvfs("/")
disk_total = (st.f_blocks * st.f_frsize) // (1024**3)
disk_used  = ((st.f_blocks - st.f_bfree) * st.f_frsize) // (1024**3)
disk_pct   = round(100 * disk_used / disk_total)

print(f"CPU:{cpu}")
print(f"RAM:{ram_used}|{ram_total}|{ram_pct}")
print(f"DISK:{disk_used}|{disk_total}|{disk_pct}")
SCRIPT
chmod +x "$BIN_DIR/shiraos-sysinfo"
ok "shiraos-sysinfo"

# shiraos-accent — cor adaptativa do wallpaper
cat > "$BIN_DIR/shiraos-accent" << 'SCRIPT'
#!/usr/bin/env python3
import sys, subprocess, os, colorsys

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")

def get_current_wallpaper():
    # Tenta swww query
    try:
        r = subprocess.run(["swww", "query"], capture_output=True, text=True)
        for line in r.stdout.split("\n"):
            if "image:" in line.lower() or ".jpg" in line or ".png" in line:
                path = line.split(":")[-1].strip()
                if os.path.exists(path):
                    return path
    except: pass
    # Fallback: imagem mais recente
    imgs = []
    for ext in ["*.jpg","*.jpeg","*.png","*.webp"]:
        import glob
        imgs += glob.glob(f"{WALLPAPER_DIR}/**/{ext}", recursive=True)
    if imgs:
        return max(imgs, key=os.path.getmtime)
    return None

def extract_accent(path):
    try:
        from colorthief import ColorThief
        ct = ColorThief(path)
        palette = ct.get_palette(color_count=10, quality=3)
        best = None
        best_sat = 0
        for r, g, b in palette:
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            # Prefere cores saturadas e não muito escuras
            score = s * (0.4 + 0.6 * v)
            if s > 0.25 and v > 0.2 and score > best_sat:
                best_sat = score
                best = (r, g, b)
        if best:
            return "#{:02x}{:02x}{:02x}".format(*best)
    except ImportError:
        pass

    # Fallback: imagemagick
    try:
        r = subprocess.run([
            "magick", path, "-resize", "150x150",
            "-modulate", "100,150",
            "-format", "%c", "histogram:info:-"
        ], capture_output=True, text=True, timeout=10)
        # Pega a cor mais frequente não-cinza
        for line in sorted(r.stdout.strip().split("\n"), reverse=True):
            if "#" in line:
                hex_color = line.split("#")[1][:6]
                r2 = int(hex_color[0:2], 16)
                g2 = int(hex_color[2:4], 16)
                b2 = int(hex_color[4:6], 16)
                h, s, v = colorsys.rgb_to_hsv(r2/255, g2/255, b2/255)
                if s > 0.3 and v > 0.2:
                    return f"#{hex_color.lower()}"
    except: pass

    return "#4a90e2"  # fallback azul

wp = get_current_wallpaper()
if wp:
    accent = extract_accent(wp)
    print(f"accent:{accent}")
else:
    print("accent:#4a90e2")
SCRIPT
chmod +x "$BIN_DIR/shiraos-accent"
ok "shiraos-accent"

# shiraos-lyrics — busca letra LRC via LRCLIB
cat > "$BIN_DIR/shiraos-lyrics" << 'SCRIPT'
#!/usr/bin/env python3
import subprocess, json, sys, urllib.parse, urllib.request

def get_mpris_info():
    try:
        players = subprocess.run(
            ["playerctl", "-l"], capture_output=True, text=True
        ).stdout.strip().split("\n")
        player = next((p for p in players if "spotify" in p.lower()), players[0] if players else None)
        if not player: return None, None, None

        title  = subprocess.run(["playerctl", "-p", player, "metadata", "title"],  capture_output=True, text=True).stdout.strip()
        artist = subprocess.run(["playerctl", "-p", player, "metadata", "artist"], capture_output=True, text=True).stdout.strip()
        dur    = subprocess.run(["playerctl", "-p", player, "metadata", "mpris:length"], capture_output=True, text=True).stdout.strip()
        dur_s  = int(dur) // 1000000 if dur.isdigit() else 0
        return title, artist, dur_s
    except:
        return None, None, None

title, artist, dur = get_mpris_info()
if not title:
    print("ERROR:No player")
    sys.exit(1)

# Busca na LRCLIB
try:
    q = urllib.parse.urlencode({"track_name": title, "artist_name": artist, "duration": dur})
    url = f"https://lrclib.net/api/get?{q}"
    req = urllib.request.Request(url, headers={"User-Agent": "ShiraOS/1.0"})
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read())
    
    lrc = data.get("syncedLyrics") or data.get("plainLyrics", "")
    if lrc:
        print(lrc)
    else:
        print("ERROR:No lyrics found")
except Exception as e:
    print(f"ERROR:{e}")
SCRIPT
chmod +x "$BIN_DIR/shiraos-lyrics"
ok "shiraos-lyrics"

# ──────────────────────────────────────────────────────
# 7. Compilar plugin C++ e instalar corretamente
# ──────────────────────────────────────────────────────
step "Compilando plugin C++ (MultiEffect blur)"

QML_SHIRAOS_DIR="/usr/lib/qt6/qml/ShiraOS"

if [ -f "$CONFIG_DIR/build.sh" ]; then
    info "Executando build.sh..."
    cd "$CONFIG_DIR"
    if bash build.sh; then
        ok "Plugin compilado"
    else
        warn "Build falhou — ShiraOS funciona mas sem blur nativo"
        cd "$HOME"
    fi
    cd "$HOME"

    # Copiar as .so para o diretório correto (o cmake install não faz isso)
    PLUGIN_BUILD="$CONFIG_DIR/build/plugin"
    if [ -f "$PLUGIN_BUILD/libShiraOSPlugin.so" ]; then
        sudo mkdir -p "$QML_SHIRAOS_DIR"
        sudo cp "$PLUGIN_BUILD/libShiraOSPlugin.so"       "$QML_SHIRAOS_DIR/"
        sudo cp "$PLUGIN_BUILD/libShiraOSPluginplugin.so" "$QML_SHIRAOS_DIR/"
        ok ".so copiadas para $QML_SHIRAOS_DIR"
    else
        warn "libShiraOSPlugin.so não encontrada em $PLUGIN_BUILD"
    fi

    # Criar qmldir se não existir ou estiver incompleto
    if [ ! -f "$QML_SHIRAOS_DIR/qmldir" ] || ! grep -q "plugin ShiraOSPlugin" "$QML_SHIRAOS_DIR/qmldir" 2>/dev/null; then
        printf 'module ShiraOS\nplugin ShiraOSPlugin\n' | sudo tee "$QML_SHIRAOS_DIR/qmldir" > /dev/null
        ok "qmldir criado em $QML_SHIRAOS_DIR"
    else
        ok "qmldir já correto"
    fi

    # Verificar resultado final
    if [ -f "$QML_SHIRAOS_DIR/libShiraOSPlugin.so" ] && [ -f "$QML_SHIRAOS_DIR/qmldir" ]; then
        ok "Módulo ShiraOS instalado e pronto"
    else
        warn "Instalação incompleta — verifique $QML_SHIRAOS_DIR"
    fi
else
    warn "build.sh não encontrado — plugin C++ não compilado"
fi

# ──────────────────────────────────────────────────────
# 8. Criar diretórios necessários
# ──────────────────────────────────────────────────────
step "Criando estrutura de diretórios"

mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Wallpapers/static
mkdir -p ~/Pictures/Wallpapers/live      # para mpvpaper/mpv wallpapers
mkdir -p ~/.cache/shiraos
ok "Diretórios criados"

# ──────────────────────────────────────────────────────
# 9. Configurar Hyprland automaticamente
# ──────────────────────────────────────────────────────
step "Configurando Hyprland"

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

HYPR_BLOCK='
# ╔══════════════════════════════════════════════════════╗
# ║              ShiraOS — Hyprland                      ║
# ╚══════════════════════════════════════════════════════╝

# ── Blur nas camadas da island e wallpaper ──────────────
layerrule = blur namespace:shiraos-island
layerrule = ignore_alpha 0.05 namespace:shiraos-island
layerrule = blur namespace:shiraos-expanded
layerrule = ignore_alpha 0.05 namespace:shiraos-expanded
layerrule = blur namespace:shiraos-wallpaper
layerrule = ignore_alpha 0.05 namespace:shiraos-wallpaper

# ── Transparência de janelas ────────────────────────────
windowrule {
    name = spotify-opacity
    match:class = Spotify
    opacity = 0.6
}
windowrule {
    name = discord-opacity
    match:class = discord
    opacity = 0.8
}
windowrule {
    name = code-oss-opacity
    match:class = code-oss
    opacity = 0.8
}
windowrule {
    name = zen-opacity
    match:class = zen
    opacity = 0.9
}
windowrule {
    name = telegram-opacity
    match:class = org.telegram.desktop
    opacity = 0.8
}
windowrule {
    name = steam-opacity
    match:class = steam
    opacity = 0.8
}

# ── Teclas globais ShiraOS ──────────────────────────────
bind = SUPER, Super_L, exec, qs -c shiraos ipc call shiraos toggleIsland
bind = SUPER, W,       exec, qs -c shiraos ipc call shiraos toggleWallpaper

# ── Tamanhos rápidos de janela ──────────────────────────
bind = SUPER ALT, 1, resizeactive, exact 800 600
bind = SUPER ALT, 2, resizeactive, exact 1280 720
bind = SUPER ALT, 3, resizeactive, exact 1920 1080
bind = SUPER ALT, C, centerwindow

# ── Apps ────────────────────────────────────────────────
bind = SUPER, F, exec, zen-browser

# ── Toggle blur (3 <-> 5 passes) ───────────────────────
bind = SUPER, G, exec, hyprctl keyword decoration:blur:passes $(hyprctl getoption decoration:blur:passes | grep int | awk '"'"'{print ($2 == 5 ? 3 : 5)}'"'"')

# ── Autostart ───────────────────────────────────────────
exec-once = swww-daemon
exec-once = shiraos
'

if [ ! -f "$HYPR_CONF" ]; then
    warn "hyprland.conf não encontrado em $HYPR_CONF"
    echo "$HYPR_BLOCK"
else
    cp "$HYPR_CONF" "$HYPR_CONF.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
    ok "Backup salvo"
    sed -i '/ShiraOS \xe2\x80\x94 Hyprland/,/exec-once = shiraos$/d' "$HYPR_CONF"
    sed -i '/exec-once.*shiraos$/d' "$HYPR_CONF"
    sed -i '/exec-once.*swww-daemon/d' "$HYPR_CONF"
    printf '%s\n' "$HYPR_BLOCK" >> "$HYPR_CONF"
    ok "Configurações do ShiraOS injetadas no hyprland.conf"
figurações do ShiraOS injetadas no hyprland.conf"
figurações do ShiraOS injetadas no hyprland.conf"
figurado para o ShiraOS"
    else
        # Backup antes de mexer
        cp "$HYPR_CONF" "$HYPR_CONF.bak_shiraos_$(date +%Y%m%d_%H%M%S)"
        ok "Backup salvo: ${HYPR_CONF}.bak_shiraos_*"

        # Remover exec-once duplicados do ShiraOS se existirem de versão anterior
        sed -i '/exec-once.*shiraos/d' "$HYPR_CONF"
        sed -i '/exec-once.*swww-daemon/d' "$HYPR_CONF"

        # Adicionar o bloco completo no final
        printf '%s\n' "$HYPR_BLOCK" >> "$HYPR_CONF"
        ok "Configurações do ShiraOS adicionadas ao hyprland.conf"

        info "Blocos adicionados:"
        info "  layerrule blur (island, expanded, wallpaper)"
        info "  bind SUPER → toggleIsland"
        info "  bind SUPER+W → toggleWallpaper"
        info "  exec-once swww-daemon + shiraos"
    fi
fi

# ──────────────────────────────────────────────────────
# 10. PATH
# ──────────────────────────────────────────────────────
step "Verificando PATH"

FISH_CONF="$HOME/.config/fish/config.fish"

# Fish — usar fish_add_path (persiste entre sessões)
if [ -f "$FISH_CONF" ]; then
    if ! grep -q "fish_add_path.*local/bin\|local/bin.*fish_add_path" "$FISH_CONF"; then
        echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CONF"
        ok "~/.local/bin adicionado ao config.fish"
    else
        ok "config.fish já tem ~/.local/bin"
    fi
fi

# Bash/Zsh — fallback
if ! grep -q "local/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    ok "~/.local/bin adicionado ao .bashrc"
fi

# Exportar para a sessão atual do bash (para o shiraos funcionar logo após o install)
export PATH="$BIN_DIR:$PATH"
ok "PATH atualizado para esta sessão"

# ──────────────────────────────────────────────────────
# 11. Resumo final
# ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     ShiraOS instalado com sucesso!       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Se 'shiraos' não funcionar neste terminal, rode:${NC}"
echo -e "  ${CYAN}source ~/.config/fish/config.fish${NC}  ${NC}(fish)${NC}"
echo -e "  ${CYAN}source ~/.bashrc${NC}                   ${NC}(bash)${NC}"
echo ""
echo -e "  Para iniciar:    ${CYAN}shiraos${NC}"
echo -e "  Para parar:      ${CYAN}shiraos stop${NC}"
echo -e "  Para reiniciar:  ${CYAN}shiraos restart${NC}"
echo -e "  Para debug:      ${CYAN}shiraos debug${NC}"
echo ""
echo -e "  Config em:  ${CYAN}$CONFIG_DIR${NC}"
echo -e "  Scripts em: ${CYAN}$BIN_DIR${NC}"
echo -e "  Plugin em:  ${CYAN}/usr/lib/qt6/qml/ShiraOS/${NC}"
echo ""
echo -e "  ${YELLOW}⚠ Reinicie o Hyprland para aplicar as layerrules e binds!${NC}"
echo ""
