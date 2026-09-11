# FiorenDot

Personal dotfiles and system configurations for **Arch Linux** running **Hyprland** Wayland compositor.

---

## Preview

https://github.com/user-attachments/assets/d04b9009-9919-40bc-a0a7-0fad74e87f09

---

## System Stack & Components

| Component | Software / Tool | Description |
| :--- | :--- | :--- |
| **OS** | Arch Linux | Rolling-release base |
| **Compositor** | Hyprland | Dynamic tiling Wayland compositor |
| **Status Bar** | Waybar | Custom modules & layout (`Fioren V1`) |
| **App Launcher** | Rofi-wayland | Application menu, beats, wallpapers, calculator |
| **Overview** | Quickshell | Lightweight workspace overview with live window previews |
| **Notification** | SwayNC | Wayland notification daemon & control center |
| **Terminals** | Kitty / Ghostty | GPU-accelerated terminal emulators |
| **Shell** | Zsh + Oh My Zsh | Shell environment with plugins & completions |
| **Prompt** | Starship | Cross-shell customizable prompt |
| **Theming / Colors** | Wallust | Automatic color palette generation from wallpaper |
| **Power Menu** | Wlogout | Logout, lock, reboot, and power options |
| **Visualizer** | Cava | Audio visualizer |
| **System Monitor**| Btop | Terminal resource monitor |
| **Screenshots** | Swappy + Grim/Slurp | Screen capture & annotation |
| **GTK & Qt Theme**| GTK 3/4, Kvantum, Qt5ct, Qt6ct | Unified desktop theme & styling |

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/Leshoraa/FiorenDot.git ~/FiorenDot
cd ~/FiorenDot
```

### 2. Run the installer

The included `install.sh` script automates backing up any existing configurations in `~/.config` before creating links or copying files.

```bash
# Preview actions without making changes
./install.sh --dry-run

# Symlink configurations (recommended for tracking dotfiles)
./install.sh --symlink

# Alternatively, copy files directly
./install.sh --copy
```

#### Flags

- `-s, --symlink`: Symlink files into `~/.config` and `~/` (default).
- `-c, --copy`: Copy files instead of symlinking.
- `-n, --dry-run`: Display actions without modifying disk.
- `--no-backup`: Disable automatic backup of existing config folders.
- `-h, --help`: Display command usage.

---

## Keybindings Reference

| Shortcut | Action |
| :--- | :--- |
| `Super + Return` | Open default terminal (Kitty / Ghostty) |
| `Super + A` | Toggle desktop workspace overview (Quickshell) |
| `Super + D` | Open Rofi application launcher |
| `Super + T` | Open default file manager |
| `Super + B` | Open default web browser |
| `Super + Space` | Toggle floating mode & center window |
| `Super + Shift + F` | Toggle fullscreen |
| `Super + Alt + F` | Toggle maximize |
| `Super + Q` / `Super + C` | Close active window |
| `Super + Alt + V` | Open clipboard manager |
| `Super + Alt + R` | Refresh Waybar, SwayNC, and desktop components |
| `Super + Alt + O` | Toggle blur mode (Optimized / Ultra Blur) |
| `Super + H` | Toggle keybind cheat sheet |
| `Super + Alt + E` | Emoji picker |

*User-specific key overrides are defined in `.config/hypr/UserConfigs/UserKeybinds.conf`.*

---

## Dependencies

Ensure the following packages are installed on Arch Linux:

```bash
sudo pacman -S hyprland waybar rofi-wayland swaync kitty zsh starship cava btop swappy grim slurp kvantum qt5ct qt6ct
```

Optional/AUR tools:
```bash
yay -S wallust-git wlogout ghostty fastfetch quickshell
```

---

## License & Credits

- Configurations maintained by [Leshoraa](https://github.com/Leshoraa).
- Base Hyprland structure inspired by the Arch-Hyprland community.
