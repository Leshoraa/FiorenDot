#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_SRC="${1:-/usr/bin/rofi}"
ROFI_DST="${HOME}/.local/bin/rofi"

if [ ! -f "$ROFI_SRC" ]; then
    echo "Error: Source rofi binary not found at $ROFI_SRC" >&2
    exit 1
fi

mkdir -p "$(dirname "$ROFI_DST")"

echo "==> Patching rofi to use ON_DEMAND keyboard interactivity (2) instead of EXCLUSIVE (1)..."
python3 - << PYEOF
import sys, os

src = "$ROFI_SRC"
dst = "$ROFI_DST"

with open(src, 'rb') as f:
    data = bytearray(f.read())

# mov $0x1, %r9d ; xor %r8d, %r8d ; mov %eax, %ecx ; mov $0x4, %esi
pattern = b'\x41\xb9\x01\x00\x00\x00\x45\x31\xc0\x89\xc1\xbe\x04\x00\x00\x00'
idx = data.find(pattern)
if idx == -1:
    # Check if already patched
    patched_pattern = b'\x41\xb9\x02\x00\x00\x00\x45\x31\xc0\x89\xc1\xbe\x04\x00\x00\x00'
    if data.find(patched_pattern) != -1:
        print("==> rofi source is already patched.")
    else:
        print("Error: Could not locate set_keyboard_interactivity bytecode in rofi binary.", file=sys.stderr)
        sys.exit(1)
else:
    data[idx + 2] = 0x02  # Change 0x01 (EXCLUSIVE) to 0x02 (ON_DEMAND)

with open(dst, 'wb') as f:
    f.write(data)

os.chmod(dst, 0o755)
print(f"==> Successfully installed patched rofi to {dst}")
PYEOF

echo "==> Done! Patched rofi is ready at $ROFI_DST."
