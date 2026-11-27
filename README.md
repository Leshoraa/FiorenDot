# FiorenDot

> Hardware-specific Arch Linux + Hyprland dotfiles built for the **ASUS Vivobook S 14 Flip TN3402QA** (`leviola`).

Personal workstation & 2-in-1 convertible setup featuring custom ACPI/power tuning, stateful battery charge thresholds, infinite spatial canvas workflows, dynamic OKLCH/Wallust theming, and safe external display hotplug handling.

> [!CAUTION]
> **Strict Device Lock**: Do **not** blindly run `./install.sh` or copy `system/` configs onto other machines. Several components are pinned to this chassis and will break non-matching hardware:
> 1. **Boot / ACPI (`acpi_override.img`, `loader-linux.conf`)**: Injects a custom SSDT (`CpuPlugA` / `ZPSS`) and forces `amd_pstate=active amdgpu.runpm=1 amdgpu.bapm=1` for Ryzen 5 5600H (Cezanne).
> 2. **Battery Threshold (`asus-battery-charge-threshold.service`)**: Writes to ASUS-specific sysfs (`/sys/class/power_supply/BATT/charge_control_end_threshold`).
> 3. **Touchpad NumberPad (`asus_touchpad_numpad.service`)**: Binds a uinput daemon to the `TN3402QA` NumberPad matrix.
> 4. **Touchscreen & Rotation (`TouchRotate.sh`)**: Targets device ID `wdht1f01:00-2575:0911` and convertible sensor transforms.
> 5. **Display Geometry**: Waybar, Quickshell, floating presets (`795x482`), and infinite canvas coordinates are tuned for `1920x1200@60Hz` (`scale 1.2`) and `scrcpy` (`1220x2712`).
>
> *If you only want visual configs, cherry-pick `.config/waybar`, `.config/wallust`, `.config/kitty`, or `.config/swaync` manually.*

---

## Preview

https://github.com/user-attachments/assets/d04b9009-9919-40bc-a0a7-0fad74e87f09

---

## Key Features

### 1. Battery Health & Power Management
* **Persistent Manual Limit (80% / 100%)**: Persists your chosen `charge_control_end_threshold` (`80` or `100`) across reboots, AC unplug, and suspend/resume (`asus-battery-charge-threshold.service`, `battery-limit-rtc.sh`, and `udev` without waking the laptop during sleep).
* **Safe 100% Soak Revert**: Toggle full charge from SwayNC (`󰂄 Charge 100%`) or `BatteryLimitToggle.sh`; automatically reverts to `80%` only after staying plugged in at `>= 99%` / `Full` for 2 hours (`SOAK_SECONDS=7200`).
* **AC/Battery Boost Sync**: Tracks per-battery Turbo Boost preference and tunes `vm.dirty_writeback_centisecs` (`500` on AC / `1500` on battery) on AC transitions cleanly.

### 2. Finityren (Infinite 2D Canvas)
* **Spatial Window Navigation**: Moves focus using Euclidean distance and directional cones instead of linear window cycling.
* **Atomic Canvas Panning**: Shifts floating window coordinates via `hl.dsp.window.move` with `Super + Alt + Drag` (mouse or absolute touchpad).
* **Overview Coexistence**: Automatically pauses keyboard, cache, collision, and panning loops whenever Phantomat is active (`/tmp/phantom_active`).

### 3. Wallust Palette & Wallpaper Engine
* **OKLCH Contrast Guard**: Keeps dark surfaces grounded while preserving high-contrast accent colors from active wallpapers.
* **Images & Video**: Supports static images (`awww`) and video wallpapers (`mpvpaper`), hot-reloading Hyprland, Waybar (`SIGUSR2`), SwayNC, Rofi, Kitty, Ghostty, and Starship.

### 4. Smart External Display & Projector Manager
* **Non-Destructive Hotplug**: Keeps `eDP-1` (`1920x1200@60Hz`, `0x0`, `scale 1.2`) and primary workspaces (`1`–`5`) pinned on the laptop panel when connecting HDMI displays or projectors.
* **Flicker-Free Mode Selection**: Automatically selects `50–62 Hz` with `bitdepth = 8` and `vrr = 0` on external outputs, with instant Extend / Mirror / Laptop Only / External Only switching (`XF86Display` or `Super + Ctrl + P`).

### 5. 2-in-1 Convertible & Touchscreen Support
* **On-Demand Touch Input**: Disabled on boot to prevent accidental touches; toggle anytime with `Super + Shift + T`.
* **Auto Rotation & Virtual Keyboard**: `TouchRotate.sh` syncs display + stylus/touch transforms and auto-shows patched `wvkbd` (`Super` key patch + `Super + K` tablet auto-show toggle).
* **Multi-Touch Gestures**: `touchscreen-gestures.service` provides hardware-level 2–5 finger taps and swipes.

### 6. Audio, Networking & Offline Productivity
* **EasyEffects DSP**: Tuned EQ presets and RNNoise mic suppression.
* **Conflict-Free mDNS**: `system/network/no-mdns.conf` disables duplicate mDNS in `systemd-resolved` (`MulticastDNS=no`) so `avahi-daemon` resolves `.local` cleanly without hostname collisions.
* **Performance Stack**: `systemd-zram-generator` (`zstd`, 50% RAM) and passwordless sysfs udev rules.
* **Offline Tools**: Tesseract screen OCR (`eng+ind` -> `wl-copy`), Rofi project launcher (`~/Projects`), and Qalculate modal.

---

## System Stack & Components

| Component | Software / Tool | Description |
| :--- | :--- | :--- |
| **OS** | Arch Linux | Rolling-release base with Linux Zen / Dynamic kernel |
| **Compositor** | Hyprland 0.57+ | Dynamic tiling Wayland compositor configured via Lua (`hyprland.lua`) |
| **Status Bar** | Waybar | Custom modules & layout (`Fioren V1`) with Cava visualizer & live workspace sync |
| **Notification Center** | SwayNC | Notification daemon (`swaync.service`), control center, and quick setting toggles |
| **Overview** | Quickshell | Native workspace overview with live window previews |
| **Spatial Overview** | Phantomat (patched) | Grid overview with aligned borders, safe floating drag, and live Socket2 workspace sync |
| **App Launcher** | Rofi-wayland | Application menu, RofiBeats, wallpaper picker, calculator |
| **Terminals** | Kitty / Ghostty | GPU-accelerated terminal emulators with daemon mode |
| **Shell & Prompt** | Zsh + Oh My Zsh + Starship | Rich completions, autosuggestions, syntax highlighting |
| **Theming Engine** | Wallust + Caelestia | Dynamic wallpaper-based palette generation |
| **Power Menu** | Wlogout | Fast lock, sleep, reboot, and shutdown modal |
| **Audio Server** | PipeWire + WirePlumber | Low-latency modern Linux audio subsystem |
| **Audio Processing** | EasyEffects | DSP equalizer, loudness normalizer, RNNoise suppression |
| **Virtual Keyboard** | wvkbd (custom patch) | Touchscreen on-screen keyboard with Super key support |
| **Screen Capture** | Grim + Slurp + Swappy | Region screenshotting and integrated annotation tool |

---

## Keybindings Reference

### Window & Workspace Management
| Shortcut | Action |
| :--- | :--- |
| `Super + Return` | Open default terminal (Kitty / Ghostty) |
| `Super + Shift + Return` | Toggle DropDown terminal |
| `Super + Q` | Terminate active process gracefully |
| `Super + Shift + Q` | Force close active window (`killactive`) |
| `Super + Space` | Toggle floating, resize to standard, and center window |
| `Super + Ctrl + Space` | Float all windows in active workspace |
| `Super + Shift + F` | Toggle true fullscreen |
| `Super + Alt + F` | Toggle pseudo-fullscreen (maximize) |
| `Super + A` | Toggle Quickshell desktop overview |
| `Super + Ctrl + S` | Window switcher menu |

### Infinite Canvas (Finityren)
| Shortcut | Action |
| :--- | :--- |
| `Super + Alt + Left Drag` | Pan entire canvas of floating windows simultaneously |
| `Super + Alt + Touchpad Drag`| Pan canvas via multi-touch touchpad gestures (no click needed) |
| `Super + Alt + Arrow Keys` | Seamlessly navigate & fly focus to nearest spatial window |
| `Super + Alt + Space` | Pseudo-fullscreen, scale, and center target canvas window |

### Spatial Overview (Phantomat)
| Shortcut | Action |
| :--- | :--- |
| `Alt + Tab` / `Super + Alt + Space` | Toggle Spatial Overview (zoom out, grid layout, & live Waybar sync) |
| `Tab` / `Shift + Tab` | Cycle windows across workspaces while updating active workspace |
| `Super + Alt + Arrow Keys` | Navigate selection / workspaces in overview |
| `Super + =` / `Super + +` | Zoom in overview camera |
| `Super + -` | Zoom out overview camera |
| `Super + 0` | Reset / fit all workspaces in overview |
| `Super + Shift + A` | Tidy and arrange windows on grid |

### Applications & Launchers
| Shortcut | Action |
| :--- | :--- |
| `Super + D` | Open Rofi application launcher |
| `Super + T` | Open default file manager (Thunar) |
| `Super + B` | Open default web browser |
| `Super + N` | Toggle SwayNC notification center & quick controls |
| `Super + Shift + N` | Toggle Do Not Disturb (DND) for notifications / gaming |
| `Super + Shift + O` | Screen OCR / Snip-to-Text directly to clipboard |
| `Super + Shift + D` | Toggle on-screen annotation layer (Wayscriber) |
| `Super + Shift + P` | Quick Project Launcher (Enter: Codium, Shift+Enter: Kitty) |
| `Super + K` | Toggle tablet mode virtual keyboard auto-show |
| `Super + Shift + T` | Toggle touchscreen input on / off |
| `Super + S` | Quick web search dialog |
| `Super + Alt + C` | Open smart Rofi calculator with history tape |
| `Super + Alt + V` | Open clipboard history manager |
| `Super + Alt + E` | Open emoji picker |
| `Super + Shift + M` | Online streaming music player (RofiBeats) |
| `Alt + P` / `Power Button` | Open power & session menu (Wlogout) |

### Wallpapers & Visuals
| Shortcut | Action |
| :--- | :--- |
| `Super + W` | Interactive wallpaper selector (Images & Videos) |
| `Super + Shift + W` | Select random wallpaper with debounced Wallust theme |
| `Super + Alt + W` | Apply wallpaper post-processing effects |
| `Super + Alt + O` | Toggle blur mode (Optimized vs Ultra Blur) |
| `Super + Shift + G` | Toggle Hyprland Game Mode (disables animations/blur) |
| `Super + Alt + R` | Hot-refresh Waybar, SwayNC, and desktop components |
| `Super + Alt + Scroll Down` | Zoom in desktop viewport |
| `Super + Alt + Scroll Up` | Zoom out desktop viewport |
| `Super + Alt + Middle Click`| Reset desktop zoom to 1.0x |

### Touchscreen Gestures
| Gesture | Action |
| :--- | :--- |
| `2-Finger Single Tap` | Open / toggle Rofi application launcher |
| `3-Finger Single Tap` | Open / close on-screen virtual keyboard (wvkbd) |
| `4-Finger Single Tap` | Open default terminal (Kitty) |
| `5-Finger Single Tap` | Close active application window (Kill active) |
| `2-Finger Swipe Right`| Switch to next workspace |
| `2-Finger Swipe Left` | Switch to previous workspace |
| `3-Finger Swipe Up` | Toggle Quickshell desktop overview |
| `3-Finger Swipe Down` | Toggle special workspace (scratchpad) |
| `3-Finger Swipe Left / Right`| Switch workspace (+1 / -1) |
| `4-Finger Swipe Up` | Open SwayNC notification center |
| `4-Finger Swipe Down` | Open Rofi application launcher |
| `4-Finger Swipe Left / Right`| Move active window to next / previous workspace |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Leshoraa/FiorenDot.git ~/Projects/FiorenDot
cd ~/Projects/FiorenDot
```

### 2. Run the Automated Installer

The included `install.sh` script backs up existing configurations in `~/.config` before linking files:

```bash
# Preview actions safely without making disk changes
./install.sh --dry-run

# Symlink configurations (recommended to maintain git sync)
./install.sh --symlink

# Or copy configurations directly
./install.sh --copy
```

### 3. Package Dependencies

#### Arch Linux (Official Repositories)
```bash
sudo pacman -S hyprland waybar rofi-wayland swaync kitty zsh starship cava btop swappy grim slurp kvantum qt5ct qt6ct easyeffects jq python tesseract tesseract-data-eng tesseract-data-ind
```

#### AUR Packages
```bash
yay -S wallust-git wlogout ghostty fastfetch quickshell awww wvkbd
```

### 4. Enable Background Services

Enable user services for battery protection, gestures, and audio:
```bash
systemctl --user daemon-reload
systemctl --user enable --now battery-protection.service
systemctl --user enable --now easyeffects.service
systemctl --user enable --now touchscreen-gestures.service
```

Add your user to the `input` group for touchpad/input event access:
```bash
sudo usermod -aG input $USER
```

---

## Repository Structure

```text
FiorenDot/
├── .config/
│   ├── hypr/               # Hyprland configs, UserConfigs, UserScripts & scripts
│   ├── swaync/             # Notification daemon, custom CSS & button grid
│   ├── waybar/             # Status bar modules, layouts, and styles
│   ├── wallust/            # Dynamic palette templates & configuration
│   ├── rofi/               # Application menus, beats, themes, calculator, projects
│   ├── kitty/              # Kitty terminal configuration & wallust themes
│   ├── ghostty/            # Ghostty modern terminal configuration
│   ├── quickshell/         # Workspace overview QML definitions
│   └── systemd/user/       # User systemd units (battery-protection, etc.)
├── .local/
│   ├── bin/                # Custom helper binaries & scripts
│   └── share/easyeffects/  # Tuned audio DSP presets (Harman Kardon, Dolby)
├── system/                 # Kernel sysfs, udev, network, power, zen, wvkbd & phantomat patches
├── wallpapers/             # Curated aesthetic wallpapers
├── install.sh              # Interactive setup and deployment script
├── sync-from-system.sh     # Sync active system & /etc configs back into the repo
└── README.md               # System documentation & reference
```

---

## License & Credits
- Designed and maintained by **Fioren (@Leshoraa)**.
- Configured for **ASUS Vivobook S 14 Flip**.

