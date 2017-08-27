#!/bin/bash

run_in_chroot() {
  local command="$@"
  arch-chroot /mnt $command
}

echo "Beginning installation..."
echo "pacstrapping using base installation files..."
pacstrap /mnt base grub openssh ntp

run_in_chroot grub-install --target=i386-pc /dev/sda
run_in_chroot grub-mkconfig -o /boot/grub/grub.cfg
