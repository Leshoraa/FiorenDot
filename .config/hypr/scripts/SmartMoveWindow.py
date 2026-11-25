#!/usr/bin/env python3
# /* ---- 💫 FiorenDot / Hyprland Smart Window Move 💫 ---- */
# Moves tiled windows smoothly and intuitively:
# Sequence: Left (1) <-> Top (2) <-> Right (3), with full Up/Down/Stack support.

import sys
import os
import json
import time
import socket

def hypr_cmd(cmd):
    sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    if not sig:
        import subprocess
        if cmd.startswith('j/'):
            return subprocess.check_output(['hyprctl', cmd[2:], '-j']).decode('utf-8')
        elif cmd.startswith('eval '):
            return subprocess.run(['hyprctl', 'eval', cmd[5:]], stdout=subprocess.PIPE, text=True).stdout
        return ''

    sock_path = f"/run/user/{os.getuid()}/hypr/{sig}/.socket.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(sock_path)
        s.sendall(cmd.encode('utf-8'))
        res = b''
        while True:
            chunk = s.recv(8192)
            if not chunk:
                break
            res += chunk
    return res.decode('utf-8', errors='replace')

def hypr_eval(lua_code):
    return hypr_cmd(f'eval {lua_code}')

def get_hypr_data():
    active = json.loads(hypr_cmd('j/activewindow'))
    clients = json.loads(hypr_cmd('j/clients'))
    layout_data = json.loads(hypr_cmd('j/getoption general:layout'))
    return active, clients, layout_data.get('str', 'dwindle')

def fallback_move(direction, is_floating):
    if is_floating:
        deltas = {'l': (-40, 0), 'r': (40, 0), 'u': (0, -30), 'd': (0, 30)}
        dx, dy = deltas.get(direction, (0, 0))
        hypr_eval(f'hl.dispatch(hl.dsp.window.move({{ x = {dx}, y = {dy}, relative = true }}))')
    else:
        hypr_eval(f'hl.dispatch(hl.dsp.window.move({{ direction = "{direction}" }}))')

def classify_3windows(tiled_windows, active_addr):
    min_x = min(w['at'][0] for w in tiled_windows)
    min_y = min(w['at'][1] for w in tiled_windows)
    max_x = max(w['at'][0] + w['size'][0] for w in tiled_windows)
    max_y = max(w['at'][1] + w['size'][1] for w in tiled_windows)
    total_w = max_x - min_x
    total_h = max_y - min_y
    mid_x = min_x + total_w / 2
    mid_y = min_y + total_h / 2
    
    master_win = None
    layout_type = None
    
    for w in tiled_windows:
        if w['size'][1] > total_h * 0.7:
            master_win = w
            layout_type = 'left_master' if (w['at'][0] < mid_x) else 'right_master'
            break
        elif w['size'][0] > total_w * 0.7:
            master_win = w
            layout_type = 'top_master' if (w['at'][1] < mid_y) else 'bottom_master'
            break
            
    if not layout_type:
        return 'unknown', 'unknown'
        
    active_w = next((w for w in tiled_windows if w['address'] == active_addr), None)
    if not active_w or not master_win:
        return layout_type, 'unknown'
        
    if active_w['address'] == master_win['address']:
        win_role = 'master'
    else:
        on_left = (active_w['at'][0] + active_w['size'][0] / 2) < mid_x
        on_top = (active_w['at'][1] + active_w['size'][1] / 2) < mid_y
        if on_left and on_top:
            win_role = 'top_left'
        elif not on_left and on_top:
            win_role = 'top_right'
        elif on_left and not on_top:
            win_role = 'bottom_left'
        else:
            win_role = 'bottom_right'
            
    return layout_type, win_role

def get_3win_action(layout_type, win_role, direction):
    # 1. Master windows
    if win_role == 'master':
        if layout_type == 'left_master':
            if direction == 'r': return 'target_top'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'
            if direction == 'l': return 'stay'
        elif layout_type == 'top_master':
            if direction == 'r': return 'target_right'
            if direction == 'l': return 'target_left'
            if direction == 'd': return 'target_bottom'
            if direction == 'u': return 'stay'
        elif layout_type == 'right_master':
            if direction == 'l': return 'target_top'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'
            if direction == 'r': return 'stay'
        elif layout_type == 'bottom_master':
            if direction == 'r': return 'target_right'
            if direction == 'l': return 'target_left'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'stay'

    # 2. Stack windows
    if layout_type == 'left_master':
        if win_role == 'top_right':
            if direction == 'd': return 'swap_d'
            if direction == 'l': return 'target_top'
            if direction == 'r': return 'target_right'
            if direction == 'u': return 'target_top'
        elif win_role == 'bottom_right':
            if direction == 'u': return 'swap_u'
            if direction == 'l': return 'target_left'
            if direction == 'r': return 'target_right'
            if direction == 'd': return 'target_bottom'
            
    elif layout_type == 'top_master':
        if win_role == 'bottom_left':
            if direction == 'r': return 'swap_r'
            if direction == 'l': return 'target_left'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'
        elif win_role == 'bottom_right':
            if direction == 'l': return 'swap_l'
            if direction == 'r': return 'target_right'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'
            
    elif layout_type == 'right_master':
        if win_role == 'top_left':
            if direction == 'd': return 'swap_d'
            if direction == 'r': return 'target_top'
            if direction == 'l': return 'target_left'
            if direction == 'u': return 'target_top'
        elif win_role == 'bottom_left':
            if direction == 'u': return 'swap_u'
            if direction == 'r': return 'target_right'
            if direction == 'l': return 'target_left'
            if direction == 'd': return 'target_bottom'
            
    elif layout_type == 'bottom_master':
        if win_role == 'top_left':
            if direction == 'r': return 'swap_r'
            if direction == 'l': return 'target_left'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'
        elif win_role == 'top_right':
            if direction == 'l': return 'swap_l'
            if direction == 'r': return 'target_right'
            if direction == 'u': return 'target_top'
            if direction == 'd': return 'target_bottom'

    return 'fallback'

def execute_3win_target(target, active_addr, active_ws, others):
    if len(others) < 2:
        return
    wb, wc = others[0], others[1]
    preselects = {
        'target_left': ('r', 'd'),
        'target_top': ('d', 'r'),
        'target_right': ('l', 'd'),
        'target_bottom': ('u', 'r'),
    }
    if target not in preselects:
        return
    p1, p2 = preselects[target]
    code = (
        f"hl.dispatch(hl.dsp.window.move({{ workspace = 'special:temp', follow = false, window = 'address:{wb}' }})); "
        f"hl.dispatch(hl.dsp.window.move({{ workspace = 'special:temp', follow = false, window = 'address:{wc}' }})); "
        f"hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }})); "
        f"hl.dispatch(hl.dsp.layout('preselect {p1}')); "
        f"hl.dispatch(hl.dsp.window.move({{ workspace = '{active_ws}', follow = false, window = 'address:{wb}' }})); "
        f"hl.dispatch(hl.dsp.focus({{ window = 'address:{wb}' }})); "
        f"hl.dispatch(hl.dsp.layout('preselect {p2}')); "
        f"hl.dispatch(hl.dsp.window.move({{ workspace = '{active_ws}', follow = false, window = 'address:{wc}' }})); "
        f"hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }}))"
    )
    hypr_eval(code)

def main():
    if len(sys.argv) < 2:
        sys.exit(0)
    
    direction = sys.argv[1].lower()[0] # 'l', 'r', 'u', 'd'
    if direction not in ('l', 'r', 'u', 'd'):
        sys.exit(0)
        
    try:
        active, clients, layout = get_hypr_data()
    except Exception:
        sys.exit(0)
        
    if not active or not active.get('address'):
        sys.exit(0)
        
    if active.get('floating', False):
        fallback_move(direction, True)
        sys.exit(0)
        
    if layout != 'dwindle':
        fallback_move(direction, False)
        sys.exit(0)
        
    active_ws = active.get('workspace', {}).get('id')
    active_addr = active['address']
    
    # Debounce for tiled movement so holding key doesn't spin layout out of control
    now = time.time()
    last_file = f"/tmp/smart_move_tiled_last_{active_ws}"
    try:
        with open(last_file, 'r') as f:
            last_time = float(f.read().strip())
    except Exception:
        last_time = 0.0
    if now - last_time < 0.22:
        sys.exit(0)
    with open(last_file, 'w') as f:
        f.write(str(now))

    # Filter tiled windows on current workspace
    tiled_windows = [
        c for c in clients 
        if c.get('workspace', {}).get('id') == active_ws 
        and not c.get('floating', False)
        and c.get('mapped', True)
    ]
    
    count = len(tiled_windows)
    if count <= 1 or count > 3:
        fallback_move(direction, False)
        sys.exit(0)
        
    # Handle 2 windows
    if count == 2:
        other = [w for w in tiled_windows if w['address'] != active_addr][0]
        min_x = min(w['at'][0] for w in tiled_windows)
        min_y = min(w['at'][1] for w in tiled_windows)
        max_x = max(w['at'][0] + w['size'][0] for w in tiled_windows)
        max_y = max(w['at'][1] + w['size'][1] for w in tiled_windows)
        total_w = max_x - min_x
        total_h = max_y - min_y
        mid_x = min_x + total_w / 2
        mid_y = min_y + total_h / 2

        is_vert_split = (active['size'][1] > total_h * 0.7)
        if is_vert_split:
            is_left = active['at'][0] < mid_x
            if (direction == 'r' and is_left) or (direction == 'l' and not is_left):
                hypr_eval(f'hl.dispatch(hl.dsp.window.swap({{ direction = "{direction}" }}))')
            elif direction in ('u', 'd'):
                p = 'd' if direction == 'u' else 'u'
                code = f"hl.dispatch(hl.dsp.window.move({{ workspace = 'special:temp', follow = false, window = 'address:{other['address']}' }})); hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }})); hl.dispatch(hl.dsp.layout('preselect {p}')); hl.dispatch(hl.dsp.window.move({{ workspace = '{active_ws}', follow = false, window = 'address:{other['address']}' }})); hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }}))"
                hypr_eval(code)
        else: # Horizontal split
            is_top = active['at'][1] < mid_y
            if (direction == 'd' and is_top) or (direction == 'u' and not is_top):
                hypr_eval(f'hl.dispatch(hl.dsp.window.swap({{ direction = "{direction}" }}))')
            elif direction in ('l', 'r'):
                p = 'r' if direction == 'l' else 'l'
                code = f"hl.dispatch(hl.dsp.window.move({{ workspace = 'special:temp', follow = false, window = 'address:{other['address']}' }})); hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }})); hl.dispatch(hl.dsp.layout('preselect {p}')); hl.dispatch(hl.dsp.window.move({{ workspace = '{active_ws}', follow = false, window = 'address:{other['address']}' }})); hl.dispatch(hl.dsp.focus({{ window = 'address:{active_addr}' }}))"
                hypr_eval(code)
        sys.exit(0)
        
    # Handle 3 windows
    others = [w['address'] for w in tiled_windows if w['address'] != active_addr]
    others.sort()
    
    layout_type, win_role = classify_3windows(tiled_windows, active_addr)
    action = get_3win_action(layout_type, win_role, direction)
    
    if action == 'stay':
        sys.exit(0)
    elif action.startswith('swap_'):
        swap_dir = action.split('_')[1]
        hypr_eval(f'hl.dispatch(hl.dsp.window.swap({{ direction = "{swap_dir}" }}))')
    elif action.startswith('target_'):
        execute_3win_target(action, active_addr, active_ws, others)
    else:
        fallback_move(direction, False)

if __name__ == '__main__':
    main()
