#!/usr/bin/env bash
# FiorenDot - Screen OCR
# Author: Fioren (@Leshoraa)

if ! command -v tesseract >/dev/null 2>&1; then
    notify-send -u critical -i "dialog-warning" \
        "Tesseract OCR Missing" \
        "Install via terminal:\nsudo pacman -S tesseract tesseract-data-eng tesseract-data-ind" \
        -a "OCR"
    exit 1
fi

GEOM=$(slurp 2>/dev/null)

if [ -z "$GEOM" ]; then
    exit 0
fi

TMP_IMG=$(mktemp /tmp/ocr_snip_XXXXXX.png)
if ! grim -g "$GEOM" "$TMP_IMG" 2>/dev/null; then
    rm -f "$TMP_IMG"
    exit 1
fi

LANG_OPTS="eng"
if tesseract --list-langs 2>/dev/null | grep -q "ind"; then
    LANG_OPTS="eng+ind"
fi

EXTRACTED_TEXT=$(tesseract "$TMP_IMG" stdout -l "$LANG_OPTS" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
rm -f "$TMP_IMG"

if [ -n "$EXTRACTED_TEXT" ]; then
    printf "%s" "$EXTRACTED_TEXT" | wl-copy

    PREVIEW=$(echo "$EXTRACTED_TEXT" | head -n 3)
    LINE_COUNT=$(echo "$EXTRACTED_TEXT" | wc -l)
    if [ "$LINE_COUNT" -gt 3 ]; then
        PREVIEW="${PREVIEW}\n..."
    fi

    notify-send -i "edit-paste" \
        "OCR Copied to Clipboard" \
        "$PREVIEW" \
        -a "OCR"
else
    notify-send -i "dialog-information" \
        "OCR" \
        "No readable text detected in selected area." \
        -a "OCR"
fi
