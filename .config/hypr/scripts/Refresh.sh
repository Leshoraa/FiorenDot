#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Modified by: Fioren (@Leshoraa)

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

file_exists() {
  if [ -e "$1" ]; then return 0; else return 1; fi
}

_ps=(rofi ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

if pidof waybar >/dev/null; then
  touch "$HOME/.config/waybar/style.css"
else
  waybar &
fi

pkill qs 2>/dev/null || true

if systemctl --user is-active --quiet swaync.service || systemctl --user is-enabled --quiet swaync.service; then
  systemctl --user restart swaync.service
else
  pkill swaync >/dev/null 2>&1 || true
  swaync >/dev/null 2>&1 &
  sleep 0.2
  swaync-client --reload-config >/dev/null 2>&1 || true
fi

# Reset and balance audio channels (fixes one-sided audio bug in Zen Browser & other apps)
if [ -x "${SCRIPTSDIR}/FixAudioBalance.sh" ]; then
  "${SCRIPTSDIR}/FixAudioBalance.sh" &
fi

# Relaunching rainbow borders if the script exists
#if file_exists "${UserScripts}/RainbowBorders.sh"; then
#  ${UserScripts}/RainbowBorders.sh &
#fi

exit 0