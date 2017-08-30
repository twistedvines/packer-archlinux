#!/bin/bash

echo 'installing guest additions...'

pacstrap /mnt expect

arch-chroot /mnt expect -c \
'set timeout 60
spawn pacman -S virtualbox-guest-utils
expect -re "Enter a number .*:" {
  after 100 { send -- "2\r" }
}
expect {Proceed with installation? [Y/n] }
send -- "y\r"
expect eof'
