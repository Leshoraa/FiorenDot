#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds so they always cycle windows globally (no layout-specific behavior)
# This avoids double-actions when layouts change.

set -euo pipefail

# Always reset and bind SUPER+J/K the same way on startup
hyprctl keyword unbind SUPER,J || true
hyprctl keyword unbind SUPER,K || true

# Cycle windows globally: J = next
hyprctl keyword bind SUPER,J,cyclenext

# Super + K is reserved for toggling on-screen virtual keyboard
hyprctl keyword bindd "SUPER,K,Toggle virtual keyboard on/off,exec,$HOME/.config/hypr/UserScripts/VirtualKeyboardToggle.sh"
