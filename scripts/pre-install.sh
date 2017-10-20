#!/bin/bash

create_disk() {
  parted -s /dev/sda mklabel msdos \
    mkpart primary 512KiB 300MiB set 1 boot on \
    mkpart primary 300MiB 10% \
    mkpart primary 10% 25% \
    mkpart primary 25% 100%

  mkfs.ext2 /dev/sda1
  mkfs.ext4 /dev/sda2
  mkfs.ext4 /dev/sda3
  mkfs.ext4 /dev/sda4
}

# sync-up time
echo "enabling ntp..."
timedatectl set-ntp true

echo "creating disk..."
create_disk

echo "mounting filesystems..."
mount /dev/sda2 /mnt
mkdir /mnt/var
mount /dev/sda3 /mnt/var
mkdir /mnt/home
mount /dev/sda4 /mnt/home
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
