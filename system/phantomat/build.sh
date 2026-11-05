#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/phantomat-build"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/spatial-overview"
REPO_URL="https://github.com/kaolti/phantomat.git"
COMMIT="a1e8a0806541640d01503ac861a8a39548de8724"

echo "==> Preparing Phantomat build environment in $BUILD_DIR..."
if [ ! -d "$BUILD_DIR/.git" ]; then
    mkdir -p "$(dirname "$BUILD_DIR")"
    git clone "$REPO_URL" "$BUILD_DIR"
fi

cd "$BUILD_DIR"
git fetch origin
git checkout "$COMMIT" -f
git reset --hard "$COMMIT"

if [ -f "$DIR/phantomat-fixes.patch" ]; then
    echo "==> Applying Phantomat custom fixes patch..."
    patch -p1 < "$DIR/phantomat-fixes.patch"
fi

echo "==> Compiling Phantomat plugin..."
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j"$(nproc)"

echo "==> Installing to $TARGET_DIR/spatialoverview.so..."
mkdir -p "$TARGET_DIR"
cp -f build/libspatialoverview.so "$TARGET_DIR/spatialoverview.so"
strip --strip-unneeded "$TARGET_DIR/spatialoverview.so" 2>/dev/null || true

echo "==> Reloading Hyprland plugins..."
hyprctl reload || true

echo "==> Done! Installed: $TARGET_DIR/spatialoverview.so"
