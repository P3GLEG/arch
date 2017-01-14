#!/bin/bash
set -e

echo "Checking UEFI enabled"
ls /sys/firmware/efi/efivars
if [ $? -eq 0 ]; then
    echo "Not in UEFI mode! Exiting..."
    echo "If you forget, cause of the redbull check out UNetBootin for bootable usbs"
    exit 1
fi

echo "cgdisk /dev/sdX
ORDER IS IMPORTANT FOR SCRIPT BRAH
Disk 1 512MB+ EFI Parition
Disk 2 512MB+ Boot partition
Disk 3 2GB Swap parition
Disk 4 Everything else for LVM
"
read -p "Setup your paritions and input the block driver letter following /dev/sdX..." letter

blockdevice="/dev/sd$letter"
mkfs.vfat -F32 "${blockdevice}1"
mkfs.ext4 "${blockdevice}2"
mkswap "${blockdevice}3"
mkfs.ext4 "${blockdevice}4"
cryptsetup -c aes-xts-plain64 -y --use-random luksFormat "${blockdevice}4"
cryptsetup luksOpen "${blockdevice}4" luks

pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate -l +100%FREE vg0 --name root
mkfs.ext4 /dev/mapper/vg0-root

mount /dev/mapper/vg0-root /mnt 
swapon "${blockdevice}3"
mkdir /mnt/boot
mount "${blockdevice}2" /mnt/boot
mkdir /mnt/boot/efi
mount "${blockdevice}1" /mnt/boot/efi

pacstrap /mnt base base-devel grub-efi-x86_64 zsh vim git efibootmgr dialog 

genfstab -pU /mnt >> /mnt/etc/fstab
echo "tmpfs   /tmp    tmpfs   defaults,noatime,mode=1777  0   0" >> /mnt/etc/fstab 

arch-chroot /mnt /bin/bash
ln -sf /usr/share/zoneinfo/PST8PDT /etc/localtime
hwclock --systohc --utc
echo "PwnLab" > /etc/hostname
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf

echo "vim /etc/mkinitcpio.conf 
Add 'ext4' to MODULES\nAdd 'encrypt' and 'lvm2' to HOOKS before filesystems"
read -p "Hit the any key when it's done...."
mkinitcpio -p linux
grub-install
echo "Change use_lvmetad to 0 if you have errors in grub-mkconfig"
grub-mkconfig -o /boot/grub/grub.cfg







