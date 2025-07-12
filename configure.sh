#!/bin/bash
set -e

echo "💻 Installing minimal KDE Plasma desktop..."

pacman -Sy --noconfirm \
  xorg-server xorg-apps xorg-xinit \
  plasma-meta kde-gtk-config sddm \
  dolphin konsole \
  pipewire pipewire-audio plasma-pa \
  firefox networkmanager fwupd \
  bluez bluez-utils blueman \
  flatpak

echo "⚙️ Enabling system services..."
systemctl enable sddm
systemctl enable bluetooth
systemctl enable NetworkManager
systemctl enable --now fwupd.service

echo "📶 Setting up Wi-Fi profile for $WIFI_SSID..."
nmcli radio wifi on
nmcli device wifi rescan
nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS" name "wifi-autoconnect" || echo "⚠️  Wi-Fi connect failed"
nmcli connection modify "wifi-autoconnect" connection.autoconnect yes

echo "🎮 Installing Steam and required libraries..."

# Enable multilib if not already enabled
if ! grep -q "\[multilib\]" /etc/pacman.conf; then
  echo "🛠 Enabling multilib repo..."
  sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
  pacman -Sy
fi

# GPU + Vulkan (Intel-specific for now — can be expanded)
pacman -S --noconfirm mesa vulkan-intel

# Core Steam install
pacman -S --noconfirm steam

# Common 32-bit dependencies
pacman -S --noconfirm \
  lib32-glibc lib32-alsa-lib lib32-libpulse \
  lib32-libx11 lib32-libxtst lib32-mesa

echo "📹 Installing OBS Studio..."
pacman -S --noconfirm obs-studio

echo "✅ Desktop environment, Steam, and OBS are installed. Ready for reboot."
