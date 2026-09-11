#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/wvkbd-build"

echo "==> Preparing build environment..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [ -f "$HOME/.cache/yay/wvkbd/wvkbd-0.20.tar.gz" ]; then
    echo "==> Using local cached source..."
    tar -xzf "$HOME/.cache/yay/wvkbd/wvkbd-0.20.tar.gz" -C "$BUILD_DIR" --strip-components=1
else
    echo "==> Downloading wvkbd source..."
    curl -sL https://git.sr.ht/~proycon/wvkbd/archive/v0.20.tar.gz | tar -xz -C "$BUILD_DIR" --strip-components=1
fi

echo "==> Applying Super key patch (replacing Cmp with Sup)..."
patch -d "$BUILD_DIR" -p1 < "$DIR/wvkbd-super.patch"

echo "==> Compiling wvkbd-mobintl..."
make -C "$BUILD_DIR" -j"$(nproc)"

echo "==> Installing to ~/.local/bin/wvkbd-mobintl..."
mkdir -p "$HOME/.local/bin"
cp -f "$BUILD_DIR/wvkbd-mobintl" "$HOME/.local/bin/wvkbd-mobintl"
chmod +x "$HOME/.local/bin/wvkbd-mobintl"

echo "==> Done! Installed: $HOME/.local/bin/wvkbd-mobintl"
