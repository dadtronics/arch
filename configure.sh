#!/bin/bash
set -e

echo "📡 Connecting to Wi-Fi..."
nmcli device wifi connect "your-ssid" password "your-password"

echo "💻 Installing minimal KDE Plasma desktop..."
pacman -Sy --noconfirm \
  xorg-server xorg-apps xorg-xinit \
  plasma-meta kde-gtk-config sddm \
  dolphin konsole \
  pipewire pipewire-audio plasma-pa \
  networkmanager

echo "⚙️ Enabling system services..."
systemctl enable sddm
systemctl enable NetworkManager

echo "✅ KDE setup complete. Reboot to enter Plasma desktop."
