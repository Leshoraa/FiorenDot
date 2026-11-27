#!/usr/bin/env bash
# Launch tuigreet with Linux VT palette synced from Wallust wallpaper colors

PALETTE_FILE="/etc/greetd/tuigreet-palette"

# Apply Wallust 16-color Linux console palette if available and valid
if [ -r "$PALETTE_FILE" ]; then
    while IFS='=' read -r key raw_val; do
        val="${raw_val//\"/}"
        case "$key" in
            P[0-9A-F])
                if [[ "$val" =~ ^[0-9A-Fa-f]{6}$ ]]; then
                    idx="${key#P}"
                    printf '\033]P%s%s' "$idx" "$val"
                fi
                ;;
        esac
    done < "$PALETTE_FILE"
    printf '\033[2J\033[H'
fi

exec tuigreet \
    --time \
    --remember \
    --remember-user-session \
    --asterisks \
    --greeting "Hyprland • leviola" \
    --sessions /usr/share/wayland-sessions \
    --cmd /usr/bin/start-hyprland \
    --theme 'border=blue;text=white;prompt=magenta;time=cyan;greet=blue;action=cyan;button=blue;container=black;input=white;title=magenta'
