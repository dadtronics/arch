# Arch Linux Auto-Installer

This script performs an unattended installation of Arch Linux using a predefined disk layout and configuration.

---

## 🧾 What It Does

- Automatically detects the main system disk
- Wipes the disk and creates a GPT layout with:
  - EFI System Partition (512MiB)
  - Root partition (remaining space)
- Formats partitions (`FAT32` for EFI, `ext4` for root)
- Mounts partitions and installs base Arch packages
- Installs essential tools (e.g. `vim`, `less`, `man`, `NetworkManager`)
- Configures:
  - Timezone
  - Locale
  - Hostname
  - `/etc/hosts`
  - `fstab`
- Adds a swap file (2GB)
- Creates a user and sets passwords (root + user)
- Installs and registers a UEFI boot entry using EFI stub
- Removes leftover USB boot entries from the system

---

## 📁 Requirements

- UEFI-compatible system
- An active internet connection
- Arch Linux installation media (booted and running)
- A `.env` file containing your desired username, passwords, and hostname

---

## 🛠️ .env File

Create a `.env` file with the following contents:

```bash
USERNAME=yourusername
USERPASS=youruserpassword
ROOTPASS=yourrootpassword
HOSTNAME=yourhostname
````

> ⚠️ The script will fail if any of these variables are missing.

---

## 📶 Connecting to Wi-Fi with `iwctl`

If you're using Wi-Fi (e.g. on a laptop), connect to the internet before running the installer:

1. Launch the interactive tool:

   ```bash
   iwctl
   ```

2. Inside the `iwctl` shell:

   ```text
   # List devices
   device list

   # Scan for networks (replace wlan0 with your device)
   station wlan0 scan

   # Show networks
   station wlan0 get-networks

   # Connect to your SSID (you'll be prompted for a password)
   station wlan0 connect your-ssid
   ```

3. Verify connectivity:

   ```bash
   ping archlinux.org
   ```

> 💡 Use `exit` to leave the `iwctl` shell.

---

## ▶️ Usage

### 🔄 Clone the repository (recommended)

After connecting to the internet:

```bash
pacman -Sy --noconfirm git
git clone https://github.com/dadtronics/arch.git
cd arch
```

Make sure your `.env` file is in the cloned directory, then run:

```bash
chmod +x arch-autoinstall.sh
./arch-autoinstall.sh
```

---

### 📥 Alternate: Transfer via `scp` (if not using Git)

From another machine:

```bash
scp user@your-host:/path/to/arch-autoinstall.sh /root/
scp user@your-host:/path/to/.env /root/
```

Then on the live Arch system:

```bash
cd /root
chmod +x arch-autoinstall.sh
./arch-autoinstall.sh
```

---

## ⚠️ Warning

This script will **erase the primary system disk** without prompting. Use with caution.