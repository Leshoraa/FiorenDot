#!/usr/bin/env python3
import sys, os, time, shutil, signal, termios, tty

# 29x29 Scannable QR Code (Rickroll / Prank)
HEX_ARRAY = [
    '1fc85f7f', '105be141', '174e735d', '175abe5d', '1745cf5d', '10543941', '1fd5557f',
    '00015200', '1f7d78aa', '05a85371', '09cbf8c0', '100e632a', '0ecafa0c', '0d0d36d1',
    '0ee0e56c', '1b117172', '01dd682c', '1614d375', '125f3024', '111a3632', '1152d9f7',
    '001d051f', '1fd4af5c', '10455311', '175579f7', '17585e2f', '175b367e', '1052572a',
    '1fdb1ebc'
]

# Linux 6.10+ DRM Panic Colors
# Background: Royal Blue (#0000AA)
# Foreground: White (#FFFFFF)
BLUE_BG = '\033[48;2;0;0;170m'
WHITE_BG = '\033[48;2;255;255;255m'
BLUE_FG = '\033[38;2;0;0;170m'
WHITE_FG = '\033[38;2;255;255;255m'

def cleanup():
    sys.stdout.write('\033[?25h\033[0m\033[2J\033[H')
    sys.stdout.flush()

def draw():
    cols, rows = shutil.get_terminal_size((120, 36))
    qr_29 = [[int(c) for c in f'{int(h, 16):029b}'] for h in HEX_ARRAY]
    
    # 2-module quiet zone
    qz = 2
    size = 29 + qz * 2
    matrix = [[0] * size for _ in range(size)]
    for y in range(29):
        for x in range(29):
            matrix[y + qz][x + qz] = qr_29[y][x]

    # Tux ASCII art from drivers/gpu/drm/drm_panic.c
    tux = [
        "   .--.",
        "  |o_o |   | |",
        "  |:_/ |   | |",
        " //   \\ \\",
        "(|     | ) (_)",
        "/'\\_   _/`\\",
        "\\___)=(___/"
    ]

    msg = [
        "",
        "KERNEL PANIC!",
        "",
        "Please reboot your computer.",
        "",
        "Fatal exception in interrupt"
    ]

    # Decide rendering scale based on available terminal rows
    # If rows >= 44, use large 2x1 mode (size lines)
    # If rows < 44, use compact half-block mode ((size+1)//2 lines)
    use_large = (rows >= size + len(msg) + 4)

    qr_lines = []
    if use_large:
        qr_w_chars = size * 2
        for row in matrix:
            line = ''
            for val in row:
                if val == 1:
                    line += BLUE_BG + '  '
                else:
                    line += WHITE_BG + '  '
            qr_lines.append(line + BLUE_BG)
    else:
        qr_w_chars = size
        for y in range(0, size, 2):
            row_top = matrix[y]
            row_bot = matrix[y + 1] if y + 1 < size else [0] * size
            line = ''
            for x in range(size):
                top = row_top[x]
                bot = row_bot[x]
                if top == 1 and bot == 1:
                    line += BLUE_BG + ' '
                elif top == 0 and bot == 0:
                    line += WHITE_BG + ' '
                elif top == 1 and bot == 0:
                    line += WHITE_BG + BLUE_FG + '▀'
                else:
                    line += WHITE_BG + BLUE_FG + '▄'
            qr_lines.append(line + BLUE_BG)

    qr_h = len(qr_lines)
    msg_h = len(msg)
    total_h = qr_h + msg_h

    start_y = max(1, (rows - total_h) // 2)
    qr_x = max(0, (cols - qr_w_chars) // 2)

    buffer = []
    for r in range(rows):
        line_bg = BLUE_BG + WHITE_FG
        tux_row = r - 1
        tux_str = ('   ' + tux[tux_row]) if (0 <= tux_row < len(tux)) else ''

        c_idx = r - start_y
        if 0 <= c_idx < qr_h:
            qr_segment = qr_lines[c_idx]
            if tux_str:
                prefix = tux_str + ' ' * max(0, qr_x - len(tux_str))
            else:
                prefix = ' ' * qr_x
            suffix = ' ' * max(0, cols - qr_x - qr_w_chars)
            buffer.append(line_bg + prefix + qr_segment + line_bg + suffix)
        elif qr_h <= c_idx < total_h:
            txt = msg[c_idx - qr_h]
            txt_x = max(0, (cols - len(txt)) // 2)
            buffer.append(line_bg + ' ' * txt_x + txt + ' ' * max(0, cols - txt_x - len(txt)))
        else:
            if tux_str:
                buffer.append(line_bg + tux_str + ' ' * max(0, cols - len(tux_str)))
            else:
                buffer.append(line_bg + ' ' * cols)

    # First clear entire screen with Blue background to ensure 100% solid fill
    sys.stdout.write('\033[?25l' + BLUE_BG + '\033[2J\033[H')
    sys.stdout.flush()

    # Hide cursor, jump to (1,1), print all rows, reset colors
    sys.stdout.write('\033[H' + '\n'.join(buffer) + '\033[0m')
    sys.stdout.flush()

if __name__ == '__main__':
    time.sleep(0.08)
    signal.signal(signal.SIGWINCH, lambda s, f: draw())
    draw()
    try:
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        tty.setraw(fd)
        try:
            while True:
                ch = sys.stdin.read(1)
                # Secret exit: 'q', Esc, or Ctrl+C
                if ch in ('q', '\x03', '\x1b'):
                    break
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
            cleanup()
    except Exception:
        cleanup()
