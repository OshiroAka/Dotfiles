#!/usr/bin/env bash

set -euo pipefail

# Pasta onde este install.sh está
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

CONFIG_SRC="$INSTALL_DIR/config.jsonc"
FETCH_SRC="$INSTALL_DIR/scripts/shira-fetch"
GIF_DIR="$INSTALL_DIR/gif_fastfetch"

FASTFETCH_DIR="$HOME/.config/fastfetch"
BIN_DIR="$HOME/.local/bin"
FISH_CONF_DIR="$HOME/.config/fish/conf.d"

FASTFETCH_CONFIG_DEST="$FASTFETCH_DIR/config.jsonc"
FETCH_DEST="$BIN_DIR/shira-fetch"
FISH_SNIPPET="$FISH_CONF_DIR/shira-fetch.fish"

echo "╭────────────────────────────╮"
echo "│  Shira Fastfetch Installer │"
echo "╰────────────────────────────╯"
echo

# Verificações básicas
if [[ ! -f "$FETCH_SRC" ]]; then
  echo "Erro: script não encontrado:"
  echo "$FETCH_SRC"
  exit 1
fi

if [[ ! -d "$GIF_DIR" ]]; then
  echo "Erro: pasta de GIFs não encontrada:"
  echo "$GIF_DIR"
  exit 1
fi

if [[ ! -f "$CONFIG_SRC" ]]; then
  echo "Aviso: config.jsonc não encontrado."
  echo "O instalador vai continuar só com o shira-fetch."
  echo
fi

mkdir -p "$FASTFETCH_DIR" "$BIN_DIR" "$FISH_CONF_DIR"

# Backup da config antiga, caso exista e não seja a mesma
if [[ -e "$FASTFETCH_CONFIG_DEST" && ! -L "$FASTFETCH_CONFIG_DEST" ]]; then
  BACKUP="$FASTFETCH_CONFIG_DEST.bak.$(date +%Y%m%d-%H%M%S)"
  echo "Fazendo backup da config antiga:"
  echo "$BACKUP"
  mv "$FASTFETCH_CONFIG_DEST" "$BACKUP"
fi

# Linka config do fastfetch
if [[ -f "$CONFIG_SRC" ]]; then
  ln -sfn "$CONFIG_SRC" "$FASTFETCH_CONFIG_DEST"
  echo "Config do Fastfetch linkada:"
  echo "$FASTFETCH_CONFIG_DEST -> $CONFIG_SRC"
fi

# Linka shira-fetch para ~/.local/bin
chmod +x "$FETCH_SRC"
ln -sfn "$FETCH_SRC" "$FETCH_DEST"

echo
echo "Script linkado:"
echo "$FETCH_DEST -> $FETCH_SRC"

# Garante ~/.local/bin no PATH do fish
FISH_PATH_SNIPPET="$FISH_CONF_DIR/00-local-bin.fish"

cat > "$FISH_PATH_SNIPPET" <<'FISH_EOF'
if status is-interactive
    fish_add_path -g ~/.local/bin
end
FISH_EOF

echo
echo "PATH do Fish configurado:"
echo "$FISH_PATH_SNIPPET"

# Adiciona shira-fetch ao Fish via conf.d
cat > "$FISH_SNIPPET" <<'FISH_EOF'
if status is-interactive
    if type -q shira-fetch
        shira-fetch
    end
end
FISH_EOF

echo
echo "Inicialização no Fish configurada:"
echo "$FISH_SNIPPET"

# Avisos úteis
echo
echo "Verificando dependências..."

MISSING=0

if ! command -v fastfetch >/dev/null 2>&1; then
  echo "Faltando: fastfetch"
  MISSING=1
fi

if ! command -v kitty >/dev/null 2>&1; then
  echo "Aviso: kitty não encontrado. O GIF animado depende do kitty/kitten icat."
fi

if ! command -v kitten >/dev/null 2>&1; then
  echo "Aviso: kitten não encontrado. Normalmente ele vem junto com o kitty."
fi

if ! command -v fish >/dev/null 2>&1; then
  echo "Aviso: fish não encontrado. A inicialização automática foi criada, mas só funciona no Fish."
fi

echo
echo "GIFs encontrados:"
find "$GIF_DIR" -maxdepth 1 -type f -iname "*.gif" -printf "  - %f\n" 2>/dev/null || true

echo
if [[ "$MISSING" -eq 1 ]]; then
  echo "Instalação parcial concluída, mas falta fastfetch."
  echo "No Arch/CachyOS:"
  echo "sudo pacman -S --needed fastfetch kitty fish"
else
  echo "Instalação concluída."
  echo
  echo "Teste agora com:"
  echo "shira-fetch"
  echo
  echo "Abra um novo terminal para testar a inicialização automática."
fi
