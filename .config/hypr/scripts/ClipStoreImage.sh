#!/usr/bin/env bash
CACHE_DIR="$HOME/.cache/cliphist_thumbs"
mkdir -p "$CACHE_DIR"

tmp_img=$(mktemp /tmp/clip_store_XXXXXX.png)
cat > "$tmp_img"

if [[ ! -s "$tmp_img" ]]; then
    rm -f "$tmp_img"
    exit 0
fi

# Store in cliphist
cliphist store < "$tmp_img"

new_item=$(cliphist list | head -n 1)
if [[ "$new_item" =~ ^([0-9]+)[[:space:]] ]]; then
    item_id="${BASH_REMATCH[1]}"
    thumb="$CACHE_DIR/${item_id}_square.png"
    (
        magick "$tmp_img" -gravity center -crop 1:1 +repage -resize 416x416 "$thumb"
        rm -f "$tmp_img"
    ) &
else
    rm -f "$tmp_img"
fi
