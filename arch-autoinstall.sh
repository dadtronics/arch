#!/bin/bash
set -e

source ./.env

# Detect main disk
DISK=$(lsblk -d -e 7,11 -n -o NAME,RO,TYPE | awk '$2 == 0 && $3 == "disk" { print "/dev/" $1; exit }')
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

echo "📁 Mounting target filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$ESP_PART" /mnt/boot/efi

# Install base
echo "📦 Installing base system and core tools..."
pacstrap /mnt base linux linux-firmware intel-ucode networkmanager wpa_supplicant sudo efibootmgr bash-completion texinfo vim vi less which lsof net-tools inetutils usbutils pciutils tree

# Generate fstab
echo "📝 Generating /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Get PARTUUID for root
ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT_PART")

# Configure system inside chroot
echo "🧬 Entering chroot environment to configure system..."
arch-chroot /mnt /bin/bash <<EOF_EVAL
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
echo '%wheel ALL=(ALL) ALL' | EDITOR=tee visudo

systemctl enable NetworkManager

# Add swap
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Copy kernel/initrd to ESP
cp /boot/vmlinuz-linux /boot/efi/
cp /boot/initramfs-linux.img /boot/efi/
cp /boot/intel-ucode.img /boot/efi/

# Register EFI stub
efibootmgr --create --disk "$DISK" --part 1 \
  --label "Arch Linux (EFI Stub)" \
  --loader '\vmlinuz-linux' \
  --unicode "root=PARTUUID=$ROOT_UUID rw initrd=\\intel-ucode.img initrd=\\initramfs-linux.img quiet splash loglevel=3" \
  --verbose

# Cleanup USB entries
efibootmgr -v | grep -i 'usb\\|bootx64.efi' | while read -r line; do
  BOOTNUM=\$(echo "\$line" | grep -o 'Boot[0-9A-Fa-f]\\{4\\}' | head -n1 | cut -c5-)
  if [[ -n "\$BOOTNUM" ]]; then
    echo "🧹 Found USB or removable media entry: Boot\$BOOTNUM"
    echo "    → \$line"
    echo "⚠️  Removing Boot\$BOOTNUM from UEFI boot entries..."
    efibootmgr --bootnum "\$BOOTNUM" --delete-bootnum
  fi
done
EOF_EVAL

echo "✅ Done! Reboot and log in as '$USERNAME' (password '$USERPASS'). Hostname is '$HOSTNAME'."
