#!/usr/bin/env bash

printf "%s" "
----------------------------------------------------------------------
Changing console font.
----------------------------------------------------------------------
"
# pacman -S --noconfirm --needed terminus-font

# Set console font for easier viewing
setfont ter-v22b # Another good option: ter-132n
printf "%s\n" "Set console font to ter-v22b."

printf "\n%s" "
----------------------------------------------------------------------
Getting the COUNTRY code and TIMEZONE
based on the IP address location.
----------------------------------------------------------------------
"
# Get country code and timezone based on the IP address location
COUNTRY="$(curl --fail https://ipapi.co/country)"
TIMEZONE="$(curl --fail https://ipapi.co/timezone)"
printf "\n%s\n" "COUNTRY: ${COUNTRY}\nTIMEZONE: ${TIMEZONE}"

printf "\n%s" "
----------------------------------------------------------------------
Setting up ${COUNTRY} mirrors for faster downloads.
----------------------------------------------------------------------
"
# pacman -S --noconfirm --needed reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

reflector --save /etc/pacman.d/mirrorlist --country ${COUNTRY} \
  --protocol https --latest 20 --fastest 5 --sort rate  --download-timeout 2

pacman -Syw

printf "\n%s" "
----------------------------------------------------------------------
Synchronizing the clock and updating the keyrings.
----------------------------------------------------------------------
"
# Enable time synchronization to prevent clock dift and ensure accurate time
timedatectl --no-ask-password set-ntp true

# Enable colors and parallel downloads for pacman
sed -i "/^#Color/s/^#//;/^#ParallelDownloads/s/^#//" /etc/pacman.conf

# Update the keyrings to prevent packages from failing to install
pacman -S --noconfirm archlinux-keyring

printf "%s" "
----------------------------------------------------------------------
Configuring network manager.
----------------------------------------------------------------------
"
pacman -S --noconfirm --needed NetworkManager
systemctl enable --now NetworkManager

printf "\n%s" "
----------------------------------------------------------------------
Improving makepkg efficiency by optimizing
MAKEFLAGS and COMPRESSXZ
to utilize all "$(nproc)" available cores.
----------------------------------------------------------------------
"
sed -i "/^#MAKEFLAGS/s/^#//;s/-j2/-j$(nproc)/" /etc/makepkg.conf
sed -i "s/XZ=(xz -c -z -)/XZ=(xz -c -T $(nproc) -z -)/g" /etc/makepkg.conf

printf "%s\n%s" "/etc/makepkg.conf:" \
"$(grep -E 'MAKEFLAGS=.*|COMPRESSXZ=.*' /etc/makepkg.conf)"

printf "\n%s" "
-------------------------------------------------------------------------
Generating locale for EN and JP.
-------------------------------------------------------------------------
"
sed -i "/^#en_US.UTF-8/s/^#//;/^#ja_JP.UTF-8/s/^#//" /etc/locale.gen
locale-gen

printf "\n%s" "
-------------------------------------------------------------------------
Setting up the language to EN and the timezone to ${TIMEZONE}.
-------------------------------------------------------------------------
"
# Set the timezone
timedatectl --no-ask-password set-timezone "${TIMEZONE}"

# Enable time synchronization to prevent clock dift and ensure accurate time
timedatectl --no-ask-password set-ntp true

# Set the locale variables and keymaps
localectl --no-ask-password set-keymap us
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

printf "\t\t\t\t%s\n" "$(cat /etc/locale.conf)"
timedatectl status

printf "\n%s" "
-------------------------------------------------------------------------
Installing microcode.
-------------------------------------------------------------------------
"
# Get the CPU vendor
CPU_VENDOR="$(lscpu | awk '/^Vendor ID:/ {print $3}')"

# Install microcode
if [ "${CPU_VENDOR}" = "AuthenticAMD" ]; then
  printf "Installing AMD microcode...\n"
  pacman -S --noconfirm --needed amd-ucode
elif [ "${VENDOR}" = "GenuineIntel" ]; then
  printf "Installing Intel microcode...\n"
  pacman -S --noconfirm --needed intel-ucode
fi

exit

printf "\n%s" "
-------------------------------------------------------------------------
  Installing graphics drivers.
-------------------------------------------------------------------------
"
# Get the CPU vendor
GPU_VENDOR="$(lspci | grep "")"

if [ "${GPU_VENDOR}" ]; then
fi


exit

# Add sudo no password rights
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USERNAME}

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
