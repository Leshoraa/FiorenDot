#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

file_exists() {
  if [ -e "$1" ]; then return 0; else return 1; fi
}

_ps=(rofi swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

if pidof waybar >/dev/null; then
  killall -SIGUSR2 waybar
else
  waybar &
fi

pkill qs || true; qs -c overview >/dev/null 2>&1 &

swaync >/dev/null 2>&1 &
swaync-client --reload-config

# Restart WirePlumber audio session manager (auto-fixes audio desync/dummy output without reboot)
systemctl --user restart wireplumber 2>/dev/null || true

# Relaunching rainbow borders if the script exists
#if file_exists "${UserScripts}/RainbowBorders.sh"; then
#  ${UserScripts}/RainbowBorders.sh &
#fi

exit 0