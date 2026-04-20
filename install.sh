#!/bin/bash
# ============================================================
#  Caelestia + NothingOS Hyprland setup — Arch Linux
#  Usage: bash install.sh [--city "City"] [--win-entry 0004]
#         bash install.sh --city "Moscow" --win-entry 0003
# ============================================================
set -euo pipefail

# ── Args ────────────────────────────────────────────────────
CITY="Chelyabinsk"
WIN_ENTRY="0004"
WALLPAPER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --city)    CITY="$2";      shift 2 ;;
        --win-entry) WIN_ENTRY="$2"; shift 2 ;;
        --wallpaper) WALLPAPER="$2"; shift 2 ;;
        *) shift ;;
    esac
done

STEP=0
step() { STEP=$((STEP+1)); echo ""; echo "[$STEP] $1"; }

echo "╔══════════════════════════════════════════╗"
echo "║   Caelestia + NothingOS  ·  Arch Linux   ║"
echo "╚══════════════════════════════════════════╝"
echo "  City: $CITY  |  Windows EFI: Boot$WIN_ENTRY"

# ── 1. AUR helper ───────────────────────────────────────────
step "AUR helper"
if command -v paru &>/dev/null; then
    AUR=paru
elif command -v yay &>/dev/null; then
    AUR=yay
else
    echo "  Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
    AUR=yay
fi
echo "  Using: $AUR"

# ── 2. Pacman packages ──────────────────────────────────────
step "System packages"
sudo pacman -S --needed --noconfirm \
    hyprland hyprpaper hyprlock xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk fish sddm qt6-declarative \
    imagemagick curl git inotify-tools trash-cli \
    networkmanager lm_sensors brightnessctl \
    pipewire wireplumber pipewire-pulse \
    foot thunar btop starship eza \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    polkit-gnome gnome-keyring

# ── 3. AUR packages ─────────────────────────────────────────
step "AUR packages"
$AUR -S --needed --noconfirm \
    caelestia-shell \
    caelestia-cli \
    quickshell-git \
    app2unit \
    libcava \
    wlogout \
    adw-gtk-theme

# ── 4. Nothing fonts ────────────────────────────────────────
step "Nothing fonts (Ndot 55 + NType82)"
mkdir -p ~/.local/share/fonts
if [ ! -f ~/.local/share/fonts/Ndot55-Regular.otf ]; then
    git clone --depth 1 https://github.com/xeji01/nothingfont.git /tmp/nothingfont
    cp /tmp/nothingfont/fonts/*.otf ~/.local/share/fonts/ 2>/dev/null || true
    cp /tmp/nothingfont/fonts/*.ttf ~/.local/share/fonts/ 2>/dev/null || true
    rm -rf /tmp/nothingfont
    fc-cache -fv ~/.local/share/fonts/ >/dev/null
fi
# Also put in system dir for SDDM
sudo mkdir -p /usr/share/fonts/TTF
sudo cp ~/.local/share/fonts/Ndot*.otf /usr/share/fonts/TTF/ 2>/dev/null || true
sudo cp ~/.local/share/fonts/NType*.otf /usr/share/fonts/TTF/ 2>/dev/null || true
sudo fc-cache -fv >/dev/null
echo "  Fonts installed."

# ── 5. Caelestia dotfiles ───────────────────────────────────
step "Caelestia dotfiles"
if [ ! -d ~/.local/share/caelestia ]; then
    git clone --depth 1 https://github.com/caelestia-dots/caelestia.git \
        ~/.local/share/caelestia
fi
fish ~/.local/share/caelestia/install.fish --noconfirm

# ── 6. User config ──────────────────────────────────────────
step "User config (hypr-user.conf + shell.json)"
mkdir -p ~/.config/caelestia

# Detect primary monitor
MONITOR=$(hyprctl monitors -j 2>/dev/null | python3 -c \
    "import json,sys; m=json.load(sys.stdin); print(m[0]['name'] if m else 'DP-3')" \
    2>/dev/null || echo "DP-3")

cat > ~/.config/caelestia/hypr-user.conf << EOF
# Monitor (adjust resolution/scale to your display)
monitor = $MONITOR, preferred, auto, 1.5

# Keyboard layout Russian + English (Alt+Shift to switch)
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

# Close window
bind = Super, Q, killactive,
bind = Alt, F4, killactive,

# Allow quickshell screencopy (needed for lockscreen blur)
ecosystem {
    enforce_permissions = 0
}
EOF

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

# ── 7. Wallpaper ────────────────────────────────────────────
step "Wallpaper"
mkdir -p ~/Pictures/wallpapers

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    cp "$WALLPAPER" ~/Pictures/wallpapers/main.jpg
    WALLPAPER_FILE=~/Pictures/wallpapers/main.jpg
elif [ -f ~/Pictures/wallpaper1.png ]; then
    WALLPAPER_FILE=~/Pictures/wallpaper1.png
    echo "  Using existing ~/Pictures/wallpaper1.png"
else
    echo "  Generating gradient wallpaper..."
    convert -size 3840x2160 gradient:"#0c0e12-#1a1f2e" \
        ~/Pictures/wallpapers/main.jpg 2>/dev/null || true
    WALLPAPER_FILE=~/Pictures/wallpapers/main.jpg
fi

caelestia wallpaper -f "$WALLPAPER_FILE" -n -N 2>/dev/null || true

# ── 8. SDDM login theme ─────────────────────────────────────
step "SDDM login theme (NothingOS style)"
sudo mkdir -p /usr/share/sddm/themes/nothing-os

sudo tee /usr/share/sddm/themes/nothing-os/metadata.desktop > /dev/null << 'EOF'
[SddmGreeterTheme]
Name=NothingOS
Description=NothingOS lockscreen-style login
Version=1.0
MainScript=Main.qml
EOF

# Copy wallpaper to SDDM theme dir
sudo cp "$WALLPAPER_FILE" /usr/share/sddm/themes/nothing-os/wallpaper.jpg 2>/dev/null || true

sudo tee /usr/share/sddm/themes/nothing-os/Main.qml > /dev/null << 'QMLEOF'
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
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), "HH:mm")
            font.family: ndot55.name
            font.pixelSize: 180
            color: "#ffffff"
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    clock.text = Qt.formatTime(new Date(), "HH:mm")
                    dateLabel.text = Qt.formatDate(new Date(), "dddd, d MMMM yyyy").toUpperCase()
                }
            }
        }

        Text {
            id: dateLabel
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -16
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy").toUpperCase()
            font.family: ntype82.name
            font.pixelSize: 18
            font.letterSpacing: 3
            color: "#ffffff"
            opacity: 0.7
        }

        Item { Layout.preferredHeight: 80 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: userModel.lastUser
            font.family: ntype82.name
            font.pixelSize: 18
            color: "#ffffff"
            opacity: 0.85
            font.letterSpacing: 1
        }

        Item { Layout.preferredHeight: 16 }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 300; height: 52; radius: 26
            color: Qt.rgba(1, 1, 1, 0.15)
            border.color: Qt.rgba(1, 1, 1, passwordInput.activeFocus ? 0.9 : 0.3)
            border.width: 1.5

            Row {
                anchors.fill: parent
                anchors.leftMargin: 22; anchors.rightMargin: 14

                TextField {
                    id: passwordInput
                    width: parent.width - 44; height: parent.height
                    echoMode: TextInput.Password
                    font.family: ntype82.name; font.pixelSize: 15
                    color: "#ffffff"
                    placeholderText: "Enter password"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { color: "transparent" }
                    Keys.onReturnPressed: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
                    Component.onCompleted: forceActiveFocus()
                }

                Rectangle {
                    width: 36; height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 18
                    color: passwordInput.text.length > 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.15)
                    Text {
                        anchors.centerIn: parent; text: "→"
                        font.pixelSize: 18
                        color: passwordInput.text.length > 0 ? "#000000" : "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: sddm.login(userModel.lastUser, passwordInput.text, sessionModel.lastIndex)
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        Text {
            id: errorMsg
            Layout.alignment: Qt.AlignHCenter
            font.family: ntype82.name; font.pixelSize: 13
            color: "#ff6b6b"; text: ""; visible: text !== ""
        }
    }

    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 40
        spacing: 16
        Repeater {
            model: [["⏻", "off"], ["↻", "reboot"]]
            delegate: Rectangle {
                width: 44; height: 44; radius: 22
                color: Qt.rgba(1,1,1,0.1)
                border.color: Qt.rgba(1,1,1,0.25); border.width: 1
                Text { anchors.centerIn: parent; text: modelData[0]; font.pixelSize: 18; color: "#ffffff" }
                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData[1] === "off" ? sddm.powerOff() : sddm.reboot()
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { errorMsg.text = "Wrong password"; passwordInput.text = "" }
    }
}
QMLEOF

# Disable autologin, set theme
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf > /dev/null << EOF
[Theme]
Current=nothing-os
EOF

sudo systemctl enable sddm

# ── 9. Windows dual-boot ────────────────────────────────────
step "Windows dual-boot shortcut"
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

# Add to PATH and alias
if ! grep -q "alias win=" ~/.zshrc 2>/dev/null; then
    echo "alias win='~/.local/bin/win-transition'" >> ~/.zshrc
fi
if ! grep -q "alias win=" ~/.bashrc 2>/dev/null; then
    echo "alias win='~/.local/bin/win-transition'" >> ~/.bashrc
fi

# ── 10. Services ────────────────────────────────────────────
step "Enabling services"
sudo systemctl enable --now NetworkManager 2>/dev/null || true
systemctl --user enable wireplumber pipewire pipewire-pulse 2>/dev/null || true

# ── Done ────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║             Installation done!           ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Reboot to apply everything              ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Super+L      Lock screen                ║"
echo "║  Super+Q      Close window               ║"
echo "║  Super+F      Fullscreen                 ║"
echo "║  Super+D      Dashboard (weather etc)    ║"
echo "║  Super+T      Terminal                   ║"
echo "║  Alt+Shift    Switch language (RU/EN)    ║"
echo "║  win          Reboot to Windows          ║"
echo "╚══════════════════════════════════════════╝"
