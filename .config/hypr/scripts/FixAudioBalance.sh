#!/usr/bin/env bash
# Script to fix and equalize unbalanced audio channels (e.g. Zen Browser or other apps)

WP_STATE="$HOME/.local/state/wireplumber/stream-properties"

# 1. Sanitize stored wireplumber state for any unbalanced channel volumes or accidental MONO on stereo outputs
python3 - <<'EOF'
import os, json

p = os.path.expanduser("~/.local/state/wireplumber/stream-properties")
if os.path.exists(p):
    try:
        lines = []
        with open(p, "r") as f:
            for line in f:
                if "=" in line and "channelVolumes" in line:
                    k, v = line.split("=", 1)
                    try:
                        d = json.loads(v)
                        cv = d.get("channelVolumes", [])
                        cmap = d.get("channelMap", [])
                        
                        # If an output stream is stuck as MONO or has uneven stereo volumes
                        if k.startswith("Output/Audio:") and (cmap == ["MONO"] or len(cv) == 1):
                            d["channelMap"] = ["FL", "FR"]
                            d["channelVolumes"] = [1.0, 1.0]
                            line = f"{k}={json.dumps(d)}\n"
                        elif len(cv) == 2 and cv[0] != cv[1]:
                            m = max(cv)
                            if m <= 0:
                                m = 1.0
                            d["channelVolumes"] = [m, m]
                            line = f"{k}={json.dumps(d)}\n"
                    except Exception:
                        pass
                lines.append(line)
        with open(p, "w") as f:
            f.writelines(lines)
    except Exception:
        pass
EOF

# 2. Balance all active sink inputs that are unbalanced or belong to Zen
python3 - <<'EOF'
import json, subprocess

try:
    out = subprocess.check_output(["pactl", "-f", "json", "list", "sink-inputs"], text=True)
    inputs = json.loads(out)
    for item in inputs:
        app_name = item.get("properties", {}).get("application.name", "")
        is_zen = app_name == "Zen"
        bal = item.get("balance", 0)
        
        # If channels are uneven or it is Zen Browser
        if bal != 0 or is_zen:
            vol = item.get("volume", {})
            fl = vol.get("front-left", {}).get("value", 0)
            fr = vol.get("front-right", {}).get("value", 0)
            max_v = max(fl, fr)
            if max_v <= 0 and is_zen:
                max_v = 65536
            idx = item.get("index")
            if idx and max_v > 0:
                subprocess.run(["pactl", "set-sink-input-volume", str(idx), str(max_v), str(max_v)], check=False)
except Exception:
    pass
EOF
