#!/bin/bash
# Note - this script assumes that the system has been installed & the root fs
# is available at /mnt.

run_in_chroot() {
  local command="$@"
  arch-chroot /mnt $command
}

gen_fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab
}

configure_timezone() {
  # set time to GMT
  run_in_chroot ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
  run_in_chroot hwclock --systohc
}

configure_locales() {
  # generate locales
  run_in_chroot echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
  run_in_chroot echo "en_GB ISO-8859-1" >> /etc/locale.gen
  run_in_chroot echo "LANG=en_GB.UTF-8" >> /etc/locale.conf

  run_in_chroot locale-gen
}

configure_keyboard() {
  run_in_chroot echo "KEYMAP=uk" >> /etc/vconsole.conf
}

set_hostname() {
  run_in_chroot echo "arch-linux" >> /etc/hostname
}

set_root_password() {
  password="$(run_in_chroot openssl rand -base64 18)"
  echo "root:$password" | run_in_chroot chpasswd
  echo "root password for new build is $password"
}

gen_fstab

configure_timezone
configure_locales
configure_keyboard
set_hostname
set_root_password
