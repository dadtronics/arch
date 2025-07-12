#!/bin/bash
set -e

echo "💻 Installing minimal KDE Plasma desktop..."

pacman -Sy --noconfirm \
  xorg-server xorg-apps xorg-xinit \
  plasma-meta kde-gtk-config sddm \
  dolphin konsole \
  pipewire pipewire-audio plasma-pa \
  firefox networkmanager

echo "⚙️ Enabling system services..."
systemctl enable sddm
systemctl enable NetworkManager

echo "📶 Setting up Wi-Fi profile for $WIFI_SSID..."
nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS" name "wifi-autoconnect"
nmcli connection modify "wifi-autoconnect" connection.autoconnect yes

echo "✅ KDE setup complete. Ready for reboot."
