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
