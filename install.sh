#!/bin/bash
set -e

source ./.env

# Detect main disk
# Prompt for target disk
lsblk -d -e 7,11 -o NAME,SIZE,MODEL
read -rp "Enter the target disk (e.g., /dev/sda or /dev/nvme0n1): " DISK
echo "🧠 Using disk: $DISK"

# Handle p# vs # suffix
if [[ "$DISK" =~ nvme|mmcblk ]]; then
  ESP_PART="${DISK}p1"
  ROOT_PART="${DISK}p2"
else
  ESP_PART="${DISK}1"
  ROOT_PART="${DISK}2"
fi

# Partition and format
echo "🧹 Partitioning and formatting..."
wipefs -af "$DISK"
parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart ESP fat32 1MiB 513MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary ext4 513MiB 100%

mkfs.fat -F32 "$ESP_PART"
mkfs.ext4 -F "$ROOT_PART"

# Mount and prepare
echo "📁 Mounting target filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$ESP_PART" /mnt/boot/efi

# Install base system
echo "📦 Installing base system and core tools..."
pacstrap /mnt base linux linux-firmware intel-ucode \
  networkmanager wpa_supplicant sudo efibootmgr \
  bash-completion man-db man-pages texinfo \
  vim less which lsof net-tools inetutils \
  usbutils pciutils tree

# Generate fstab
echo "🗒️ Generating /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copy configuration script
cp ./configure.sh /mnt/root/configure.sh
chmod +x /mnt/root/configure.sh

# Get PARTUUID
ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT_PART")

# Chroot and configure
arch-chroot /mnt /bin/bash <<EOF
set -e

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

echo "root:$ROOTPASS" | chpasswd
useradd -m -G wheel "$USERNAME"
echo "$USERNAME:$USERPASS" | chpasswd
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo

# Swap file
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Copy kernel/initrd to EFI
cp /boot/vmlinuz-linux /boot/efi/
cp /boot/initramfs-linux.img /boot/efi/
cp /boot/intel-ucode.img /boot/efi/

# EFI boot entry
efibootmgr --create --disk "$DISK" --part 1 \
  --label "Arch Linux (EFI Stub)" \
  --loader '\vmlinuz-linux' \
  --unicode "root=PARTUUID=$ROOT_UUID rw initrd=\\intel-ucode.img initrd=\\initramfs-linux.img quiet splash loglevel=3" \
  --verbose

# Remove USB boot entries
efibootmgr -v | grep -i 'usb\\|bootx64.efi' | while read -r line; do
  BOOTNUM=\$(echo "\$line" | grep -o 'Boot[0-9A-Fa-f]\{4\}' | head -n1 | cut -c5-)
  if [[ -n "\$BOOTNUM" ]]; then
    efibootmgr --bootnum "\$BOOTNUM" --delete-bootnum
  fi
done
EOF

echo "✅ Done! Reboot and log in as '$USERNAME'. Hostname is '$HOSTNAME'."
