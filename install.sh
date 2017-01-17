#!/bin/bash
set -e

echo "Checking UEFI enabled"
ls /sys/firmware/efi/efivars
if [ $? -eq 0 ]; then
    echo "Not in UEFI mode! Exiting..."
    echo "If you forget, cause of the redbull check out UNetBootin for bootable usbs"
    exit 1
fi

mkfs.vfat -F32 "/dev/sda1"
mkfs.ext4 "/dev/sda2"
mkswap "/dev/sda3"
mkfs.ext4 "/dev/sda4"
cryptsetup -c aes-xts-plain64 -y --use-random luksFormat "/dev/sda4"
cryptsetup luksOpen "/dev/sda4" luks

pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate -l +100%FREE vg0 --name root
mkfs.ext4 /dev/mapper/vg0-root

mount /dev/mapper/vg0-root /mnt 
swapon "/dev/sda3"
mkdir /mnt/boot
mount "/dev/sda2" /mnt/boot
mkdir /mnt/boot/efi
mount "/dev/sda1" /mnt/boot/efi

pacstrap /mnt base base-devel grub-efi-x86_64 zsh vim git efibootmgr dialog 

genfstab -pU /mnt >> /mnt/etc/fstab
echo "tmpfs\t/tmp\ttmpfs\tdefaults,noatime,mode=1777\t0\t0" >> /mnt/etc/fstab 

arch-chroot /mnt /bin/bash
ln -sf /usr/share/zoneinfo/PST8PDT /etc/localtime
hwclock --systohc --utc
echo "PwnLab" > /etc/hostname
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf

echo "Finish the install by adding /etc/mkinitcpio.conf Add 'ext4' to MODULES\nAdd 'encrypt' and 'lvm2' to HOOKS before filesystems and run the commands in order
mkinitcpio -p linux
grub-install
In /etc/default/grub edit the line GRUB_CMDLINE_LINUX to GRUB_CMDLINE_LINUX='cryptdevice=/dev/sdX3:luks:allow-discards'
Change use_lvmetad to 0 if you have errors in grub-mkconfig
grub-mkconfig -o /boot/grub/grub.cfg
reboot"










