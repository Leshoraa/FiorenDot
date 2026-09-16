# FiorenDot

Personal dotfiles and system configurations for **Arch Linux** powered by **Hyprland** Wayland compositor. Tailored for high productivity, 2-in-1 touchscreen convertibles, intelligent battery longevity, and dynamic aesthetic theming.

---

## Preview

https://github.com/user-attachments/assets/d04b9009-9919-40bc-a0a7-0fad74e87f09

---

## Key Features & Innovations

### 1. Smart Battery Health & Longevity Management
An intelligent, automated battery protection system built directly on top of Linux kernel sysfs and systemd user services:
* **80% Battery Health Threshold**: Default charge limit locked at 80% (`charge_control_end_threshold`) to drastically reduce battery aging and prevent cell swelling. Hardware automatically bypasses the battery to AC power when the threshold is reached.
* **Temporary 100% Full-Charge Override**: Easily toggle to 100% via the SwayNC Control Center button or CLI (`BatteryLimitToggle.sh toggle`).
* **Post-100% Soak Timer**: Unlike naive timers, the 1-hour countdown only starts **after** the battery actually reaches 100% capacity, ensuring you always have full charge ready before departing.
* **Auto-Revert on Unplug (Student/Mobile Safety Net)**: Designed for flexible and unpredictable schedules. If you toggle to 100% and unplug at any time to head to campus or work, the system silently and automatically restores the 80% threshold for the next session.
* **Sleep & Reboot Persistence**: Automatically re-enforces the threshold across system reboots and wake from sleep/suspend, counteracting ASUS Embedded Controller (EC) firmware resets.
* **Streamlined Notifications**: Real-time notifications for `Charging`, `Discharging`, `Low Battery` (<15%), `Critical Battery` (≤5%), and `Charge Limit Reached`—delivered in clean English without notification icons.

### 2. Finityren (Infinite Canvas & Spatial Navigation)
Transforms your workspace into an unbounded infinite 2D canvas:
* **True Spatial Geometry**: Direct navigation calculates Euclidean distance and directional cone angles rather than simple index cycling.
* **Tear-Free Atomic Batch Movements**: Dispatches window coordinate shifts atomically via `hyprctl --batch` for 1:1 synchronized multi-window panning.
* **Touchpad & Mouse Panning**: Hold `Super + Alt` and drag with mouse or slide fingers across absolute touchpads without physical clicking.
* **Absolute Physical Centering**: Calculates the exact physical center of the monitor in logical pixels, compensating for top and bottom status bars.

### 3. Dynamic Material You Tonal Theming (Wallust + Caelestia)
* **Perceptual Color Extraction**: Uses pixel population histogram quantization with hue-excited neighbor smoothing in CIELAB / Saliencedark16 color space for high-contrast, eye-pleasing tonal palettes.
* **Static & Video Wallpaper Engine**: Full support for both ultra-high-resolution images and animated video wallpapers (`.mp4`, `.webm`, `.mkv`).
* **Instant Hot-Reload**: Wallpapers apply asynchronously via `awww` while Waybar reloads instantly via `SIGUSR2`, eliminating bar flashing and UI latency.
* **System-wide Theme Propagation**: Synchronously updates Hyprland borders, Waybar, SwayNC, Rofi, Kitty, Ghostty, and Starship prompt.

### 4. 2-in-1 Convertible & Touchscreen Integration
* **Touchscreen On-Demand**: Touchscreen input is disabled by default on startup to avoid accidental touches, and can be toggled manually at any time via `Super + Shift + T`.
* **Touchscreen Rofi Input**: Patched Rofi (`system/rofi/patch-rofi.sh`) with on-demand keyboard interactivity so that on-screen virtual keyboards (`wvkbd`) can receive touches and type directly into the app launcher without exclusive grab conflicts.
* **Auto Screen Rotation**: Dynamic sensor detection and rotation via `TouchRotate.sh` for laptop, tent, and tablet orientations.
* **Smart Tablet Virtual Keyboard**: Patched `wvkbd` with a dedicated Super key (`wvkbd-super.patch`). Pressing `Super + K` toggles whether the virtual keyboard auto-appears when entering tablet mode (active/inactive toggle), keeping the laptop mode clean while giving seamless touch typing in tablet mode.
* **Multi-Finger Touchscreen Gestures**: Hardware-level atomic multi-touch gestures running in background via `touchscreen-gestures.service`:
  * `2-Finger Tap`: Open / close application launcher (Rofi).
  * `3-Finger Tap`: Instant toggle on-screen virtual keyboard (`wvkbd`).
  * `4-Finger Tap`: Launch terminal emulator (`Kitty`).
  * `5-Finger Tap`: Close active application window (`KillActiveProcess.sh`).
  * `2-Finger Swipe Right / Left`: Switch workspace to next / previous.
  * `3-Finger Swipe Up / Down`: Open desktop overview / toggle special workspace.
  * `4-Finger Swipe Up / Down`: Open SwayNC notification panel / Rofi app launcher.

### 5. Studio-Grade Audio DSP (EasyEffects)
* **Custom Hardware Tuned Presets**: Tailored acoustic equalization profiles for Asus VivoBook speakers (Harman Kardon, Dolby Atmos, Perfect EQ).
* **AI Noise Suppression**: Deep-learning background voice isolation using RNNoise for crystal clear microphone audio.

### 6. System Performance & Power Tuning
* **ZRAM with zstd Compression**: High-throughput memory compression configured via `systemd-zram-generator`.
* **Hardware Udev Rules**: Passwordless user control for charging thresholds (`99-battery-charge-threshold.rules`).
* **Quickshell Workspace Overview**: Instant native overview with live window previews (`Super + A`).

### 7. Offline Productivity Suite (Zero Standby RAM)
* **Screen OCR / Snip-to-Text (`Super + Shift + O`)**: Select any rectangular region on screen with `slurp` + `grim` to instantly extract text via Tesseract OCR (`eng+ind`) directly to clipboard (`wl-copy`), accompanied by a desktop notification preview. 100% offline and zero persistent RAM usage.
* **Quick Project Switcher (`Super + Shift + P`)**: Fast Rofi switcher that dynamically indexes all repositories and directories in `~/Projects`. Open in editor (`Antigravity` / `Codium`) on `Enter`, terminal (`Kitty`) on `Alt + Enter`, file manager (`Thunar`) on `Alt + F`, or both on `Alt + B`.
* **Calculator (`Super + Alt + C`)**: Qalculate-powered modal with auto-copy and notification feedback.

---

## System Stack & Components

| Component | Software / Tool | Description |
| :--- | :--- | :--- |
| **OS** | Arch Linux | Rolling-release base with Linux Zen / Dynamic kernel |
| **Compositor** | Hyprland | Dynamic tiling Wayland compositor with fluid animations |
| **Status Bar** | Waybar | Custom modules & layout (`Fioren V1`) with Cava visualizer |
| **Notification Center** | SwayNC | Notification daemon, control center, and quick setting toggles |
| **Overview** | Quickshell | Native workspace overview with live window previews |
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

### Applications & Launchers
| Shortcut | Action |
| :--- | :--- |
| `Super + D` | Open Rofi application launcher |
| `Super + T` | Open default file manager (Thunar) |
| `Super + B` | Open default web browser |
| `Super + N` | Toggle SwayNC notification center & quick controls |
| `Super + Shift + N` | Toggle Do Not Disturb (DND) for notifications / gaming |
| `Super + Shift + O` | Screen OCR / Snip-to-Text directly to clipboard |
| `Super + Shift + P` | Quick Project Switcher (open in editor/terminal/files) |
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
├── system/                 # Kernel sysfs, udev rules, wvkbd patch, zram
├── wallpapers/             # Curated aesthetic wallpapers
├── install.sh              # Interactive setup and deployment script
└── README.md               # System documentation & reference
```

---

## License & Credits
- Designed and maintained by **Fioren (@Leshoraa)**.
- Configured for **ASUS Vivobook S 14 Flip**.

