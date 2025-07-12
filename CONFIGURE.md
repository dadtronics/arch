# Arch Linux Post-Install: `configure.sh`

This script sets up a minimal KDE Plasma desktop environment after the initial Arch Linux installation.

---

## 🧾 What This Script Does

- Connects to Wi-Fi using `nmcli`
- Installs:
  - Xorg (display server)
  - KDE Plasma (minimal desktop environment)
  - Dolphin (file manager), Konsole (terminal)
  - PipeWire + Plasma PA for audio
  - SDDM (KDE's display manager)
- Enables `sddm` and `NetworkManager` for automatic boot and networking

---

## 🔄 When to Use

Run this script **after the first reboot** from the base Arch install (`install.sh`). This assumes you are now booted into your new Arch system and logged in as your user.

---

## 🌐 Step 1: Connect to Wi-Fi (Temporary)

If you're using Wi-Fi, you need to connect before cloning the repository:

```bash
nmcli device wifi list
nmcli device wifi connect "your-ssid" password "your-password"
````

You can verify the connection:

```bash
ping archlinux.org
```

---

## 📥 Step 2: Download the Configure Script

Now that you're connected:

```bash
pacman -Sy --noconfirm git
git clone https://github.com/dadtronics/arch.git
cd arch
```

---

## ▶️ Step 3: Run the Script

Make it executable and run it:

```bash
chmod +x configure.sh
./configure.sh
```

---

## ⚠️ Note

This script assumes:

* You are running as the same user created during installation
* You are connected to the internet
* Your `.bashrc`, locale, and time are already configured from the install phase

---

## ✅ Done

Once complete, reboot:

```bash
reboot
```

You should be greeted by the KDE Plasma login screen.

Enjoy your new desktop!
