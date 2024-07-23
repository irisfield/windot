#!/usr/bin/env bash

# Get country code and timezone based on the IP address location
COUNTRY="$(curl --fail https://ipapi.co/country)"
TIMEZONE="$(curl --fail https://ipapi.co/timezone)"
EFI_PARTITION=""
BOOT_PARTITION=""

# Enable time synchronization to prevent clock dift and ensure accurate time
timedatectl --no-ask-password set-ntp true

# Enable colors and parallel downloads for pacman
sed -i "/^#Color/s/^#//;/^#ParallelDownloads/s/^#//" /etc/pacman.conf

# Update the keyrings to prevent packages from failing to install
pacman -S --noconfirm archlinux-keyring

# Set console font for easier viewing
pacman -S --noconfirm --needed terminus-font
setfont ter-v22b

# Function to display the menu and prompt the user to choose partitions
choose_partitions() {
  local partitions=$(lsblk -Alpfn -o NAME,FSTYPE,SIZE,TYPE | grep "part")
  local options=()
  local selected_count=0

  # Populate options array with partitions
  while IFS= read -r partition; do
      options+=("$partition")
  done <<< "$partitions"

  # Customizing the select prompt
  # PS3="Please choose an option (1-$(( ${#options[@]} ))): "

  # Prompt user to choose EFI and Boot partitions
  printf "%s\n\n" "First select the EFI partition, and then the BOOT partition."
  printf "%s\n" "Available partitions:"

  while [ $selected_count -lt 2 ]; do
    if [ $selected_count -eq 0 ]; then
      PS3="EFI partition (1-$(( ${#options[@]} ))): "
    else
      PS3="BOOT partition (1-$(( ${#options[@]} ))): "
    fi

    select opt in "${options[@]}"; do
        if [ -z "$opt" ]; then
          printf "%s\n" "Invalid option. Please select again."
        else
          if [ $selected_count -eq 0 ]; then
            selected_efi=$(printf "$opt" | awk '{print $1}')
            printf "\n%s\n\n" "You selected EFI partition: $selected_efi"
          elif [ $selected_count -eq 1 ]; then
            selected_boot=$(printf "$opt" | awk '{print $1}')
            printf "\n%s\n\n" "You selected BOOT partition: $selected_boot"
          fi
          selected_count=$((selected_count + 1))
          break
        fi
    done

    if [ $selected_count -eq 2 ]; then
      printf "Confirm selections (y/n): "
      read -r confirm
      case $confirm in
        [yY])
          printf "\n%s\n" "Confirmed. Proceeding with your selected partitions."
          ;;
        *)
          printf "\n%s\n\n" "Please reselect your partitions."
          selected_count=0
          ;;
      esac
    fi

  done
}

printf "
---------------------------------------------------------------------
Please select your EFI and BOOT partitions.
---------------------------------------------------------------------
"

# Prompt the user to choose their EFI and BOOT partitions
choose_partitions
