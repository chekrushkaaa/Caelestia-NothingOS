#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  Caelestia + NothingOS Hyprland — Arch Linux installer
#  Replicates a full NothingOS-style Hyprland desktop
#
#  Usage:
#    bash install.sh
#    bash install.sh --city "Moscow" --scale 1.25 --win-entry 0003
#
#  Flags:
#    --city        Weather city (default: Chelyabinsk)
#    --scale       Monitor scale (default: 1.5)
#    --wallpaper   Path to wallpaper image
#    --win-entry   EFI boot entry ID for Windows dual-boot
#    --no-sddm     Skip SDDM theme installation
#    --no-win      Skip Windows boot shortcut
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Defaults ────────────────────────────────────────────────
CITY=""
CREATOR="Chekrushka (https://github.com/chekrushkaaa)"
SCALE="1.5"
WIN_ENTRY=""
WALLPAPER=""
INSTALL_SDDM=true
INSTALL_WIN=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --city)       CITY="$2";       shift 2 ;;
        --scale)      SCALE="$2";      shift 2 ;;
        --wallpaper)  WALLPAPER="$2";  shift 2 ;;
        --win-entry)  WIN_ENTRY="$2";  shift 2 ;;
        --no-sddm)    INSTALL_SDDM=false; shift ;;
        --no-win)     INSTALL_WIN=false;  shift ;;
        *) echo "Unknown flag: $1"; shift ;;
    esac
done

# ── Interactive prompts if not passed via flags ──────────────
if [ -z "$CITY" ]; then
    echo ""
    read -rp "Enter your city for weather widget [Moscow]: " CITY
    CITY="${CITY:-Moscow}"
fi

STEP=0
step() { STEP=$((STEP+1)); echo -e "\n\033[1;36m[$STEP]\033[0m $1"; }
ok()   { echo -e "  \033[32m✓\033[0m $1"; }
warn() { echo -e "  \033[33m⚠\033[0m $1"; }

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  Caelestia + NothingOS  ·  Arch Linux      ║"
echo "╠════════════════════════════════════════════╣"
echo "║  City:  $CITY"
echo "║  Scale: $SCALE"
echo "║  Creator: $CREATOR"
echo "╚════════════════════════════════════════════╝"

# ═══════════════════════════════════════════════════════════════
#  1. AUR helper
# ═══════════════════════════════════════════════════════════════
step "AUR helper"
if command -v paru &>/dev/null; then
    AUR=paru; ok "paru found"
elif command -v yay &>/dev/null; then
    AUR=yay; ok "yay found"
else
    ok "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    AUR=yay
fi

# ═══════════════════════════════════════════════════════════════
#  2. System packages
# ═══════════════════════════════════════════════════════════════
step "System packages (pacman)"
sudo pacman -S --needed --noconfirm \
    hyprland hyprpaper hyprlock hyprpolkitagent \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    fish zsh sddm qt6-declarative \
    qt5-quickcontrols2 qt5-graphicaleffects qt5-svg \
    imagemagick curl git inotify-tools trash-cli \
    networkmanager lm_sensors brightnessctl \
    pipewire wireplumber pipewire-pulse \
    foot thunar btop starship eza fd ripgrep \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    polkit-gnome gnome-keyring libnotify \
    grim slurp wl-clipboard

# ═══════════════════════════════════════════════════════════════
#  3. AUR packages
# ═══════════════════════════════════════════════════════════════
step "AUR packages"
$AUR -S --needed --noconfirm \
    caelestia-shell \
    caelestia-cli \
    quickshell-git \
    app2unit \
    libcava \
    wlogout \
    adw-gtk-theme

# ═══════════════════════════════════════════════════════════════
#  4. Nothing fonts (Ndot 55 + NType82)
# ═══════════════════════════════════════════════════════════════
step "Nothing fonts"
mkdir -p ~/.local/share/fonts

if [ ! -f ~/.local/share/fonts/Ndot55-Regular.otf ]; then
    tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/xeji01/nothingfont.git "$tmpdir"
    cp "$tmpdir"/fonts/*.otf ~/.local/share/fonts/ 2>/dev/null || true
    cp "$tmpdir"/fonts/*.ttf ~/.local/share/fonts/ 2>/dev/null || true
    rm -rf "$tmpdir"
    fc-cache -fv ~/.local/share/fonts/ >/dev/null 2>&1
    ok "Fonts installed"
else
    ok "Fonts already present"
fi

# System-wide for SDDM
sudo mkdir -p /usr/share/fonts/TTF
sudo cp ~/.local/share/fonts/Ndot*.otf  /usr/share/fonts/TTF/ 2>/dev/null || true
sudo cp ~/.local/share/fonts/NType*.otf /usr/share/fonts/TTF/ 2>/dev/null || true
sudo fc-cache -fv >/dev/null 2>&1

# ═══════════════════════════════════════════════════════════════
#  5. Caelestia dotfiles
# ═══════════════════════════════════════════════════════════════
step "Caelestia dotfiles"
if [ ! -d ~/.local/share/caelestia ]; then
    git clone --depth 1 https://github.com/caelestia-dots/caelestia.git \
        ~/.local/share/caelestia
    ok "Cloned caelestia-dots"
fi
fish ~/.local/share/caelestia/install.fish --noconfirm
ok "Dotfiles installed"

# ═══════════════════════════════════════════════════════════════
#  6. Hyprland user config
# ═══════════════════════════════════════════════════════════════
step "Hyprland user config"
mkdir -p ~/.config/caelestia

# Detect primary monitor name
MONITOR=$(hyprctl monitors -j 2>/dev/null \
    | python3 -c "import json,sys;m=json.load(sys.stdin);print(m[0]['name'])" \
    2>/dev/null || echo ",")

cat > ~/.config/caelestia/hypr-user.conf << EOF
# Monitor (auto-detected: $MONITOR)
monitor = $MONITOR, preferred, auto, $SCALE

# Keyboard layout — Russian + English (Alt+Shift to switch)
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

# Close window
bind = Super, Q, killactive,
bind = Alt, F4, killactive,

# Don't steal focus on notifications
misc {
    focus_on_activate = false
}

# Allow quickshell screencopy (needed for lockscreen blur)
ecosystem {
    enforce_permissions = 0
}
EOF
ok "hypr-user.conf written"

# Fix editor (codium → code)
VARIABLES=~/.config/hypr/variables.conf
if [ -f "$VARIABLES" ]; then
    if grep -q '$editor = codium' "$VARIABLES"; then
        sed -i 's/\$editor = codium/$editor = code/' "$VARIABLES"
        ok "Fixed editor: codium → code"
    fi
fi

# ═══════════════════════════════════════════════════════════════
#  7. Caelestia shell config
# ═══════════════════════════════════════════════════════════════
step "Caelestia shell.json"
cat > ~/.config/caelestia/shell.json << EOF
{
    "appearance": {
        "transparency": {
            "enabled": true,
            "base": 0.85,
            "layers": 0.7
        }
    },
    "background": {
        "wallpaperEnabled": true,
        "desktopClock": {
            "background": { "enabled": true },
            "enabled": false
        },
        "visualiser": { "enabled": false }
    },
    "services": {
        "showLyrics": true,
        "useFahrenheit": false,
        "weatherLocation": "$CITY"
    }
}
EOF
ok "shell.json written (weather: $CITY, Celsius)"

# ═══════════════════════════════════════════════════════════════
#  8. Dark theme
# ═══════════════════════════════════════════════════════════════
step "Dark theme"
caelestia scheme set -m dark -n catppuccin -f mocha 2>/dev/null || true
ok "Catppuccin Mocha dark theme set"

# ═══════════════════════════════════════════════════════════════
#  9. Wallpaper
# ═══════════════════════════════════════════════════════════════
step "Wallpaper"
mkdir -p ~/Pictures/wallpapers

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    WALL="$WALLPAPER"
    ok "Using provided wallpaper: $WALL"
elif [ -f ~/Pictures/wallpaper1.png ]; then
    WALL=~/Pictures/wallpaper1.png
    ok "Using existing ~/Pictures/wallpaper1.png"
else
    warn "No wallpaper found. Set one later via: caelestia wallpaper -f <path> -n"
    WALL=""
fi

if [ -n "$WALL" ]; then
    caelestia wallpaper -f "$WALL" -n -N 2>/dev/null || true
    ok "Wallpaper applied"
fi

# ═══════════════════════════════════════════════════════════════
#  10. SDDM login theme
# ═══════════════════════════════════════════════════════════════
if $INSTALL_SDDM; then
    step "SDDM login theme"
    THEME_DIR=/usr/share/sddm/themes/nothing-os
    sudo mkdir -p "$THEME_DIR"

    sudo tee "$THEME_DIR/metadata.desktop" > /dev/null << 'EOF'
[SddmGreeterTheme]
Name=NothingOS
Description=NothingOS lockscreen-style login
Version=2.0
MainScript=Main.qml
EOF

    # Wallpaper for SDDM — use provided wallpaper or generate gradient
    if [ -n "$WALL" ]; then
        sudo cp "$WALL" "$THEME_DIR/wallpaper.jpg" 2>/dev/null || true
    else
        sudo convert -size 3840x2160 gradient:"#0c0e12-#1a1f2e" \
            "$THEME_DIR/wallpaper.jpg" 2>/dev/null || true
    fi

    sudo tee "$THEME_DIR/Main.qml" > /dev/null << 'QMLEOF'
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Item {
    id: root
    width: Screen.width
    height: Screen.height

    FontLoader { id: ndot55;  source: "/usr/share/fonts/TTF/Ndot55-Regular.otf" }
    FontLoader { id: ntype82; source: "/usr/share/fonts/TTF/NType82-Regular.otf" }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("wallpaper.jpg")
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: "#000"; opacity: 0.52 }

    ColumnLayout {
        anchors.centerIn: parent; spacing: 0

        Text {
            id: clock; Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), "HH:mm")
            font.family: ndot55.name; font.pixelSize: 180; color: "#fff"
            Timer { interval: 1000; running: true; repeat: true
                onTriggered: {
                    clock.text = Qt.formatTime(new Date(), "HH:mm")
                    dateLabel.text = Qt.formatDate(new Date(), "dddd, d MMMM yyyy").toUpperCase()
                }
            }
        }
        Text {
            id: dateLabel; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: -16
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy").toUpperCase()
            font.family: ntype82.name; font.pixelSize: 18; font.letterSpacing: 3
            color: "#fff"; opacity: 0.7
        }
        Item { Layout.preferredHeight: 80 }
        Text {
            Layout.alignment: Qt.AlignHCenter; text: userModel.lastUser
            font.family: ntype82.name; font.pixelSize: 18; font.letterSpacing: 1
            color: "#fff"; opacity: 0.85
        }
        Item { Layout.preferredHeight: 16 }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 300; height: 52; radius: 26
            color: Qt.rgba(1,1,1,0.15)
            border.color: Qt.rgba(1,1,1, passwordInput.activeFocus ? 0.9 : 0.3)
            border.width: 1.5
            Row {
                anchors.fill: parent; anchors.leftMargin: 22; anchors.rightMargin: 14
                TextField {
                    id: passwordInput
                    width: parent.width - 44; height: parent.height
                    echoMode: TextInput.Password
                    font.family: ntype82.name; font.pixelSize: 15; color: "#fff"
                    placeholderText: "Enter password"
                    placeholderTextColor: Qt.rgba(1,1,1,0.4)
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { color: "transparent" }
                    Keys.onReturnPressed: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
                    Keys.onEnterPressed:  sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
                    Component.onCompleted: forceActiveFocus()
                }
                Rectangle {
                    width: 36; height: 36; anchors.verticalCenter: parent.verticalCenter; radius: 18
                    color: passwordInput.text.length > 0 ? "#fff" : Qt.rgba(1,1,1,0.15)
                    Text { anchors.centerIn: parent; text: "→"; font.pixelSize: 18
                        color: passwordInput.text.length > 0 ? "#000" : "#fff" }
                    MouseArea { anchors.fill: parent
                        onClicked: sddm.login(userModel.lastUser, passwordInput.text, sessionModel.lastIndex) }
                }
            }
        }
        Item { Layout.preferredHeight: 14 }
        Text { id: errorMsg; Layout.alignment: Qt.AlignHCenter; font.family: ntype82.name
            font.pixelSize: 13; color: "#ff6b6b"; text: ""; visible: text !== "" }
    }

    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 40; spacing: 16
        Repeater {
            model: [["⏻", "off"], ["↻", "reboot"]]
            delegate: Rectangle {
                width: 44; height: 44; radius: 22
                color: Qt.rgba(1,1,1,0.1); border.color: Qt.rgba(1,1,1,0.25); border.width: 1
                Text { anchors.centerIn: parent; text: modelData[0]; font.pixelSize: 18; color: "#fff" }
                MouseArea { anchors.fill: parent
                    onClicked: modelData[1] === "off" ? sddm.powerOff() : sddm.reboot() }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed()    { errorMsg.text = "Wrong password"; passwordInput.text = "" }
        function onLoginSucceeded() { errorMsg.text = "" }
    }
}
QMLEOF

    # SDDM config
    sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Theme]
Current=nothing-os
EOF
    sudo systemctl enable sddm
    ok "SDDM theme installed"
fi

# ═══════════════════════════════════════════════════════════════
#  11. Windows dual-boot shortcut
# ═══════════════════════════════════════════════════════════════
if $INSTALL_WIN; then
    step "Windows dual-boot shortcut"

    # Auto-detect Windows EFI entry if not provided
    if [ -z "$WIN_ENTRY" ]; then
        WIN_ENTRY=$(sudo efibootmgr 2>/dev/null \
            | grep -i "windows" \
            | grep -oP '(?<=Boot)[0-9A-Fa-f]{4}' \
            | head -1)
    fi

    if [ -n "$WIN_ENTRY" ]; then
        mkdir -p ~/.local/bin
        cat > ~/.local/bin/win-transition << SCRIPT
#!/bin/bash
notify-send -u critical -t 1500 "⊞ Windows" "Switching boot target..."
for i in \$(seq 1.0 -0.1 0.0); do
    hyprctl keyword decoration:active_opacity \$i 2>/dev/null
    hyprctl keyword decoration:inactive_opacity \$i 2>/dev/null
    sleep 0.05
done
sleep 0.3
sudo efibootmgr -n $WIN_ENTRY && sudo reboot
SCRIPT
        chmod +x ~/.local/bin/win-transition

        # Add alias to shells
        for rc in ~/.zshrc ~/.bashrc; do
            if [ -f "$rc" ] && ! grep -q "alias win=" "$rc" 2>/dev/null; then
                echo "alias win='~/.local/bin/win-transition'" >> "$rc"
            fi
        done
        ok "win command → Boot$WIN_ENTRY"
    else
        warn "No Windows EFI entry found. Use --win-entry to set manually."
    fi
fi

# ═══════════════════════════════════════════════════════════════
#  12. Fix dual-boot time (RTC local for Windows compat)
# ═══════════════════════════════════════════════════════════════
step "Time settings"
sudo timedatectl set-local-rtc 1 --adjust-system-clock 2>/dev/null || true
sudo timedatectl set-ntp true 2>/dev/null || true
ok "RTC set to local time (Windows compat), NTP enabled"

# ═══════════════════════════════════════════════════════════════
#  13. Enable services
# ═══════════════════════════════════════════════════════════════
step "Enabling services"
sudo systemctl enable --now NetworkManager 2>/dev/null || true
systemctl --user enable wireplumber pipewire pipewire-pulse 2>/dev/null || true
ok "NetworkManager, PipeWire enabled"

# ═══════════════════════════════════════════════════════════════
#  Done
# ═══════════════════════════════════════════════════════════════
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║           Installation complete!           ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Reboot to apply everything.               ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Super+L       Lock screen                 ║"
echo "║  Super+Q       Close window                ║"
echo "║  Super+F       Fullscreen                  ║"
echo "║  Super+D       Dashboard (weather, etc.)   ║"
echo "║  Super+T       Terminal                    ║"
echo "║  Super+N       Sidebar / notifications     ║"
echo "║  Alt+Shift     Switch language (RU/EN)     ║"
echo "║  win           Reboot to Windows           ║"
echo "╚════════════════════════════════════════════╝"
