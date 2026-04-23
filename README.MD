<div align="center">

# Caelestia × NothingOS

**NothingOS-inspired Hyprland desktop for Arch Linux**

A one-command installer that transforms a fresh Arch + Hyprland setup into a polished NothingOS-style desktop using [Caelestia Shell](https://github.com/caelestia-dots/caelestia).

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=flat&logo=wayland&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

</div>

---

## What you get

| Component | Details |
|---|---|
| **Shell** | Caelestia Shell (QuickShell) |
| **Compositor** | Hyprland |
| **Font** | Ndot 55 + NType82 (Nothing style) |
| **Login screen** | Custom SDDM theme with clock, wallpaper & blur |
| **Lock screen** | Caelestia lock with blurred screencopy |
| **Theme** | Catppuccin Mocha (dark) |
| **Weather** | Open-Meteo (free, no API key) — your city in °C |
| **Keyboard** | US + RU with Alt+Shift toggle |
| **Dual-boot** | `win` command for smooth Windows reboot |
| **Time fix** | RTC local time for Windows compatibility |

## Installation

```bash
git clone https://github.com/chekrushkaaa/Caelestia-NothingOS.git
cd Caelestia-NothingOS
bash install.sh
```

The installer will ask for your **city** (for the weather widget).

### Advanced usage

```bash
# Skip interactive prompt — pass everything via flags
bash install.sh --city "Saint Petersburg" --scale 1.25

# Without Windows dual-boot shortcut
bash install.sh --no-win

# Custom wallpaper
bash install.sh --wallpaper ~/Pictures/my-wall.png
```

### Flags

| Flag | Description | Default |
|---|---|---|
| `--city` | City for weather widget | *(asks interactively)* |
| `--scale` | Monitor scale factor | `1.5` |
| `--wallpaper` | Path to wallpaper image | `~/Pictures/wallpaper1.png` |
| `--win-entry` | EFI boot entry for Windows | *(auto-detected)* |
| `--no-sddm` | Skip SDDM theme | — |
| `--no-win` | Skip Windows shortcut | — |

## Keybindings

| Key | Action |
|---|---|
| `Super + L` | Lock screen |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + D` | Dashboard (weather, settings) |
| `Super + T` | Terminal |
| `Super + N` | Sidebar / notifications |
| `Alt + Shift` | Switch language (RU ↔ EN) |
| `Alt + F4` | Close window (alt) |
| `win` *(terminal)* | Reboot to Windows |

## Dependencies

Installed automatically by the script:

- **System**: hyprland, hyprpaper, hyprlock, sddm, pipewire, foot, thunar
- **AUR**: caelestia-shell, caelestia-cli, quickshell-git, app2unit, libcava, wlogout
- **Fonts**: Ndot 55, NType82 (from [xeji01/nothingfont](https://github.com/xeji01/nothingfont))
- **SDDM**: qt5-quickcontrols2, qt5-graphicaleffects

## Structure

```
.
├── install.sh           # Main installer script
├── sddm-theme/
│   ├── Main.qml         # SDDM greeter (clock + password)
│   ├── metadata.desktop  # Theme metadata
│   └── theme.conf
└── README.md
```

## Credits

- [Caelestia Shell](https://github.com/caelestia-dots/caelestia) — the underlying shell
- [Ndot 55 Font](https://github.com/xeji01/nothingfont) — Nothing-style fonts
- [Hyprland](https://hyprland.org/) — Wayland compositor

---

<div align="center">

Made by **[Chekrushka](https://github.com/chekrushkaaa)**

</div>
