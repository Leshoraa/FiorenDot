#!/usr/bin/env bash
# /* ---- 💫 FiorenDot - ASUS Vivobook S 14 Flip 💫 ---- */
# Author: Fioren (@Leshoraa)
# Description: Screen OCR (Snip-to-Text) with 0 MB standby RAM footprint.
# Dependencies: grim, slurp, tesseract, wl-clipboard, libnotify

# Periksa apakah tesseract sudah terpasang
if ! command -v tesseract >/dev/null 2>&1; then
    notify-send -u critical -i "dialog-warning" \
        "Tesseract OCR Belum Terpasang" \
        "Silakan pasang via terminal:\nsudo pacman -S tesseract tesseract-data-eng tesseract-data-ind" \
        -a "FiorenDot OCR"
    exit 1
fi

# Pilih area layar menggunakan slurp
GEOM=$(slurp 2>/dev/null)

# Batalkan jika pengguna menekan Escape / klik kanan
if [ -z "$GEOM" ]; then
    exit 0
fi

# Ambil screenshot sementara
TMP_IMG=$(mktemp /tmp/ocr_snip_XXXXXX.png)
if ! grim -g "$GEOM" "$TMP_IMG" 2>/dev/null; then
    rm -f "$TMP_IMG"
    exit 1
fi

# Deteksi bahasa yang tersedia di tesseract
LANG_OPTS="eng"
if tesseract --list-langs 2>/dev/null | grep -q "ind"; then
    LANG_OPTS="eng+ind"
fi

# Ekstraksi teks dari gambar
EXTRACTED_TEXT=$(tesseract "$TMP_IMG" stdout -l "$LANG_OPTS" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
rm -f "$TMP_IMG"

# Salin ke clipboard jika teks ditemukan
if [ -n "$EXTRACTED_TEXT" ]; then
    printf "%s" "$EXTRACTED_TEXT" | wl-copy
    
    # Buat preview notifikasi (maksimal 3 baris)
    PREVIEW=$(echo "$EXTRACTED_TEXT" | head -n 3)
    LINE_COUNT=$(echo "$EXTRACTED_TEXT" | wc -l)
    if [ "$LINE_COUNT" -gt 3 ]; then
        PREVIEW="${PREVIEW}\n..."
    fi
    
    notify-send -i "edit-paste" \
        "OCR Berhasil Disalin!" \
        "$PREVIEW" \
        -a "FiorenDot OCR"
else
    notify-send -i "dialog-information" \
        "OCR Selesai" \
        "Tidak ada teks yang dapat dibaca pada area terpilih." \
        -a "FiorenDot OCR"
fi
