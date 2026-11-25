#!/usr/bin/env bash
# Author: Fioren (@Leshoraa)
# Installs Zen Browser AutoConfig for live Wallust CSS hot-reload + pacman hook

set -euo pipefail

QUIET="${1:-}"
ZEN_DIR="/opt/zen-browser-bin"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$EUID" -ne 0 ]]; then
  echo "Error: run with sudo: sudo bash $0" >&2
  exit 1
fi

if [[ ! -d "$ZEN_DIR" ]]; then
  echo "Error: Zen installation directory not found at $ZEN_DIR" >&2
  exit 1
fi

install -Dm644 "$SRC_DIR/autoconfig.js" "$ZEN_DIR/defaults/pref/autoconfig.js"
install -Dm644 "$SRC_DIR/zen-wallust.cfg" "$ZEN_DIR/zen-wallust.cfg"

# Install self-script and pacman hook if running from repo (not already /usr/local/bin)
if [[ "$SRC_DIR" != "/usr/local/bin" ]]; then
  install -Dm755 "$SRC_DIR/install-zen-hotreload.sh" /usr/local/bin/install-zen-hotreload.sh
  install -Dm644 "$SRC_DIR/autoconfig.js" /usr/local/share/zen-wallust/autoconfig.js
  install -Dm644 "$SRC_DIR/zen-wallust.cfg" /usr/local/share/zen-wallust/zen-wallust.cfg
  sed -i 's|^SRC_DIR=.*|SRC_DIR="/usr/local/share/zen-wallust"|' /usr/local/bin/install-zen-hotreload.sh
  install -Dm644 "$SRC_DIR/99-zen-wallust.hook" /etc/pacman.d/hooks/99-zen-wallust.hook
fi

if [[ "$QUIET" != "--quiet" ]]; then
  echo "Installed Zen Wallust hot-reload into $ZEN_DIR."
  echo "Restart Zen Browser once to activate live CSS hot-reloading."
fi
