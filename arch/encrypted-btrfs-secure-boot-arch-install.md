# Arch Linux Installation Notes

These notes document installing Arch Linux with the following features:
- UEFI System
- Secure Boot
- Dual Boot with Windows (Encrypted)
- Full-Disk Encryption using BTRFS on LUKS1 (until 
- Encrypted Boot Partition with GRUB 2
- Automatic Disk Decryption via TPM2 Unlocking
- [Unified Kernel Images (UKI)](https://wiki.archlinux.org/title/Unified_kernel_image)

## Preface

These notes are meant to be a collection of the knowledge that I have gathered
from various sources, primarily the [Arch
Wiki](https://wiki.archlinux.org/title/installation_guide) and YouTube.
Therefore, this is not an official guide; I recommend using these notes solely
as a reference. 

## Assumptions

An UEFI system with Windows installed before Linux and a TPM 2.0 module onboard.

## Dual Boot with Windows

Whether you are installing Windows from scratch or already have a Windows system
installed, I recommend checking out the following guides:
- [The EFI system partition created by Windows Setup is too small](https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small)
- [Replace the EFI system partition created by Windows Setup with a larger one](https://wiki.archlinux.org/title/EFI_system_partition#Replace_the_partition_with_a_larger_one)
- [Restoring an accidentally deleted EFI system partition](https://wiki.archlinux.org/title/Dual_boot_with_Windows#Restoring_an_accidentally_deleted_EFI_system_partition)

If you decide to replace the EFI system partition with a larger one
post-installation or create one before the installation during the Windows Setup
step, the recommended size is `1 GiB`.

**Note**: From this point onwards, the **EFI System Partition** may be abbreviated as **ESP**.

Before proceeding with the Arch Linux installation please ensure to follow the
following steps:

### 1. Disable Secure Boot

Disabling Secure Boot is required to boot into the Arch Linux installation
medium. Restart your computer and enter BIOS/UEFI settings, then disable Secure
Boot in the Boot options.

### 2. Disable Fast Startup and Hibernation

Disable these features using PowerShell with administrator privileges:
```powershell
Write-Host "Disabling Hibernation..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Type Dword -Value 0
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings") {
  Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0
}

Write-Host "Disabling Fast Startup..."
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name "HiberbootEnabled" -Value 0
```

### 3. Time Standard

It is recommended to configure both Linux and Windows to use UTC.
```powershell
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\TimeZoneInformation" -Name RealTimeIsUniversal -Value 1 -PropertyType DWord -Force
```

If Windows prompts to update the clock for Daylight Saving Time (DST) changes,
allow it. It will adjust the displayed time while keeping the system clock in
UTC as intended.

### 4. Shrink the Disk

Launch `diskmgmt.msc`, left click on the volume you would like to shrink e.g.
(C:) and proceed with shrinking the volume to free up space for Arch Linux.

### Tips and Tricks

#### Bluetooth Paring

When pairing Bluetooth devices between Linux and Windows installations, both
systems share the same MAC address but use different link keys during pairing.
This can cause connection issues between systems. If you encounter this issue,
refer to [bt-dualboot](https://github.com/x2es/bt-dualboot). Manual paring
methods are also described
[here](https://wiki.archlinux.org/title/Bluetooth#Dual_boot_pairing).

## Pre-installation

Boot into the Arch Linux installation media.

### Set the Console Keyboard Layout

Load your preferred keyboard layout. The default console keymap is `us`.

Available layouts can be listed with:
```zsh
localectl list-keymaps
```

My preferred layouts:
- `us` - United States keyboard
- `us-acentos` - United States-International keyboard

```zsh
loadkeys us-acentos
```

### Set the Console Font

Console fonts are located in `/usr/share/kbd/consolefonts`. These fonts are
commonly included in the live ISO, but they can also be installed with the
package `terminus-font`.

My preferred console fonts:
- `ter-132b` - Suitable for HiDPI screens with large characters
- `ter-v22b` or `ter-v24b` - Good choices for standard screens

The `n` and `b` suffixes in the font name denote normal and bold variants, respectively.

To set a specific font, use `setfont`:
```zsh
setfont ter-132b
```

**Note**: This

### Verify the Boot Mode

To verify that the system is booted in UEFI mode, check for the existence of
the directory `/sys/firmware/efi/efivars`:
```zsh
ls /sys/firmware/efi/efivars
```

If the directory does not exist, your system is booted in BIOS mode. These
instructions are intended for systems booting in UEFI mode. While most steps are the same for
both systems, there are some key distinctions. Please proceed with caution.

Differences:
- BIOS boot mode does not need an ESP unlike UEFI mode.
- BIOS is based on MBR while UEFI is based on GPT.

### Connect to the Internet

If using an Ethernet connection, plug in your Ethernet cable and move on to the
next step. If using Wi-Fi, ensure the wireless card is not blocked using
[`rfkill`](https://wiki.archlinux.org/title/Network_configuration/Wireless#Rfkill_caveat):
```zsh
# list devices
rfkill

# unblock potentially hard-blocked wireless card
rfkill unblock wlan
```

**Note:** `wlan` is a commonly used name for wireless cards. If your device uses
a different name, replace it accordingly.

To connect to a Wi-Fi, run `iwctl` and follow these steps:
```zsh
device list
station wlan scan # scan for networks
station wlan get-networks # list the networks
station wlan connect <SSID> # connect to the network
```

Verify the connection with `ping`:
```zsh
ping archlinux.org
```

### Update the System Clock

Enable time synchronization to prevent clock dift and ensure accurate time.
```zsh
timedatectl set-ntp true
```

### Preparing the Disk

The following partitions are **required** for a chosen device:
- One partition for the root directory `/`.
- For UEFI mode: an EFI system partition.

**Note:**
- **If you installed Windows before Arch Linux, the disk from which you want to
  boot already has an ESP, do not create another one, but use the existing
  partition instead.**

#### Partition Layout 

<p style="text-align: center;">UEFI with GPT</p>

Mount Point | Partition      | Type                  | Size
:-:         | :-:            | :-:                   | :-:
`/efi`     | `/dev/nvmen0p1`| EFI System            | 1 GiB
`/`         | `/dev/nvmen0p4`| Linux x86-64 Root (/) | Remainder

**Note:** The partition devices are based on my machine. Please replace the
`/dev/nvmen0p1` and `/dev/nvmen0p4` based on your machine.

Use a partitioning tool like fdisk to modify partition tables. For example: 

#### Partition the disk

**Note:** `/boot` is not required to be kept in a separate partition.

#### Format the partitions

```zsh
mkfs.btrfs /dev/nvmen0p4
```

#### Mount the file systems

For UEFI systems, mount the EFI System Partition:

```zsh
mount --mkdir /dev/nvmen0p1 /mnt/efi
```

**Note:** The EFI System Partition (ESP) can be mounted either at `/boot` or
`/efi`. However, for an encrypted `/boot`, it is
[required](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points)
to mount the ESP to `/efi`, as EFI-related files must remain unencrypted.

#### BTRFS
Create the subvolumes:
```zsh
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
```

Mount the subvolumes:
```zsh
umount /mnt
mount -o subvol=@root /dev/sda2 /mnt
mkdir -p /mnt/{home,.snapshots}
mount -o subvol=@home /dev/sda2 /mnt/home
mount -o subvol=@snapshots /dev/sda2 /mnt/.snapshots
```

Update `/etc/fstab`:
```zsh
UUID=<uuid_of_sda2>  /               btrfs   subvol=@root,defaults,noatime,space_cache,autodefrag   0 0
UUID=<uuid_of_sda2>  /home           btrfs   subvol=@home,defaults,noatime,space_cache,autodefrag   0 0
UUID=<uuid_of_sda2>  /.snapshots     btrfs   subvol=@snapshots,defaults,noatime,space_cache,autodefrag   0 0
```

### Bootloader

The bootloader must meet the following requirements:
- Support for [Btrfs](https://wiki.archlinux.org/title/GRUB#Supported_file_systems)
- Support for [detecting other operating systems](https://wiki.archlinux.org/title/GRUB#Detecting_other_operating_systems)
- Support for [booting with a LUKS-encrypted `/boot`](https://wiki.archlinux.org/title/GRUB#Encrypted_boot)

One popular bootloader that meets all these requirements is GRUB.

GRUB will be used to manage the encrypted `/boot`. GRUB has
a [feature](https://wiki.archlinux.org/title/GRUB#Encrypted_boot) that allows it
to unlock a LUKS-encrypted `/boot`.

To enable this feature encrypt the partition with /boot residing on it using
LUKS as normal. Then add the following option to `/etc/default/grub`: 
```zsh

```


### TPM2 Unlocking

There are two distinct TPM specifications: 2.0 and 1.2. Verify your system's TPM
version using:
```zsh
cat /sys/class/tpm/tpm*/tpm_version_major
```

TPM 2.0 is only comptabible with UEFI, whereas systems using BIOS or Legacy boot
can only use TPM 1.2.

(https://wiki.archlinux.org/title/Trusted_Platform_Module#Versions)

## Table of contents

- [Arch install with encrypted BTRFS (LUKS2), GRUB e AwesomeWM](#arch-install-with-encrypted-btrfs-luks2-grub-e-awesomewm)
  - [Table of contents](#table-of-contents)
  - [Download and boot](#download-and-boot)
    - [Links](#links)
  - [Adjusts during installation](#adjusts-during-installation)
    - [Set the keyboard layout](#set-the-keyboard-layout)
      - [loadkeys](#loadkeys)
      - [localectl](#localectl)
    - [Fix font size](#fix-font-size)
    - [Verify the boot mode](#verify-the-boot-mode)
    - [Connecting to the internet with Wi-Fi](#connecting-to-the-internet-with-wi-fi)
  - [Preparing the disks](#preparing-the-disks)
    - [Partition the disk](#partition-the-disk)
    - [Encrypt the partition](#encrypt-the-partition)
    - [Configure swap](#configure-swap)
    - [Create the filesystems](#create-the-filesystems)
    - [Configure the BTRFS subvolumes](#configure-the-btrfs-subvolumes)
    - [Mounting the subvolumes and partitions](#mounting-the-subvolumes-and-partitions)
    - [Setting up fstab file](#setting-up-fstab-file)
  - [Installing Arch Linux](#installing-arch-linux)
    - [Base packages](#base-packages)
    - [Configure swap encryption](#configure-swap-encryption)
    - [Install additional packages](#install-additional-packages)
    - [Configuring mkinitcpio](#configuring-mkinitcpio)
    - [Configuring locale](#configuring-locale)
    - [Setting users and passwords](#setting-users-and-passwords)
      - [Set a secure password for root user](#set-a-secure-password-for-root-user)
      - [Create an user account](#create-an-user-account)
      - [Install sudo if not installed](#install-sudo-if-not-installed)
      - [Associating the wheel group with sudo](#associating-the-wheel-group-with-sudo)
  - [Installing GRUB](#installing-grub)
    - [Search other operational systems](#search-other-operational-systems)
    - [Remember last selected entry](#remember-last-selected-entry)
  - [Post-install Tweaks](#post-install-tweaks)
    - [Timezone, Locale and Time Sync](#timezone-locale-and-time-sync)
      - [Setting up timezone](#setting-up-timezone)
      - [Enabling services for time sync](#enabling-services-for-time-sync)
    - [Hostname and Hosts File](#hostname-and-hosts-file)
      - [Set machine hostname](#set-machine-hostname)
      - [Editting the hosts file](#editting-the-hosts-file)
    - [Installing Micro Code For CPU](#installing-micro-code-for-cpu)
    - [Installing Xorg and GPU Drivers](#installing-xorg-and-gpu-drivers)
    - [Pacman configuration](#pacman-configuration)
      - [Enable multilib](#enable-multilib)
      - [Optimize downloads](#optimize-downloads)
      - [Customize output](#customize-output)
    - [Package manager for AUR](#package-manager-for-aur)
    - [Numlock at early boot (mkinitcpio)](#numlock-at-early-boot-mkinitcpio)
      - [Locale.conf With Fallback](#localeconf-with-fallback)
    - [Configure XDG directories](#configure-xdg-directories)
    - [Configuring ZDOTDIR](#configuring-zdotdir)
  - [Installing AwesomeWM](#installing-awesomewm)
    - [AwesomeWM installation](#awesomewm-installation)
    - [Window manager and login manager](#window-manager-and-login-manager)
    - [Basic applications for a desktop environment](#basic-applications-for-a-desktop-environment)
    - [Persist keyboard layout](#persist-keyboard-layout)
    - [Install flatpak](#install-flatpak)
  - [BTRFS snapshots](#btrfs-snapshots)
    - [Create first snapshot (clean install)](#create-first-snapshot-clean-install)
    - [Pacman hook for snapshots](#pacman-hook-for-snapshots)
    - [Pacman hook for grub update](#pacman-hook-for-grub-update)
    - [Restoring a snapshot](#restoring-a-snapshot)
  - [Customizations](#customizations)
  - [References](#references)

## Download and boot

Download and write the official Arch Linux ISO to a USB stick.

Usually I have a usb stick with ventoy and multiple ISOs, but if I want to write
only the Arch Linux ISO to a USB stick, I use usbimager.

It may be necessary to disable secure boot in the BIOS.

### Links

- Official Arch Linux website download page:
  - <https://archlinux.org/download/>
- Ventoy:
  - <https://www.ventoy.net>
- USBImager:
  - <https://gitlab.com/bztsrc/usbimager>
- Secure boot info on Arch Wiki:
  - <https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot>

## Adjusts during installation

I recommend using `tmux` so you can see long outputs and split the terminal if
needed.

### Set the keyboard layout

#### loadkeys

br-abnt2: Brazilian ABNT2 us: US us-acentos: US international

```sh
# PT BR ABNT2
loadkeys br-abnt2
```

#### localectl

br-abnt2: Brazilian ABNT2 us: US us-acentos: US international

```sh
# List available keymaps
localectl list-keymaps

# Set BR ABNT2
localectl set-keymap us-acentos
```

### Fix font size

The font may be to small during the installation.

Changing installation font
([reddit](https://www.reddit.com/r/archlinux/comments/cmyjec/how_do_i_increase_the_fontsize_on_a_basic_arch/) +
[arch wiki](https://wiki.archlinux.org/title/HiDPI#Linux_console)):

```sh
# List available fonts
ls /usr/share/kbd/consolefonts/

# Change to another font (my recomendation: ter-132n)
setfont ter-132n
```

### Verify the boot mode

If you are using UEFI, the directory `/sys/firmware/efi/efivars` should exist.

```sh
# If the directory does not exist, the system is booted in BIOS mode
ls /sys/firmware/efi/efivars
```

### Connecting to the internet with Wi-Fi

If you are using Wi-Fi, execute `iwctl` and the following commands:

```sh
device list # list the devices
station <wlan> scan # scan for networks
station <wlan> get-networks # list the networks
station <wlan> connect <SSID> # connect to the network
```

ps: you can test the connection with `ping archlinux.org`.

## Preparing the disks

I will delete all partitions on the disk and create new ones. If you have data
on the disk, backup it before continuing or adjust the steps to keep the data.

### Partition the disk

Use `fdisk` to partition the disk.

```sh
# Start the fdisk interactive mode (for the example, it will be "/dev/sda" disk)
fdisk /dev/sda

# List all partitions
p

# Create a new GPT partition layout (this will erase all data on the disk)
g

# Create a new partition (partition for EFI)
# 500M should be enough, however, I prefer to use 1G to be sure
n
> Partition number (1-128, default 1): # use default
> First sector (2048-1048575966, default 2048): # use default
> Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-1048575966, default 1048575966): +1G

# Set the type EFI
t
> Partition type or alias (type L to list all): 1 # EFI

# Create a second partition (partition for /boot (grub))
# 500M should be enough here too
n
> Partition number (2-128, default 2): # use default
> First sector (1026048-1048575966, default 1026048): # use default
> Last sector, +/-sectors or +/-size{K,M,G,T,P} (1026048-1048575966, default 1048575966): +1G

# (Optional) Create a swap partition
# 8G should be fine for most cases
n
> Partition number (3-128, default 3): # use default
> First sector (2050048-1048575966, default 2050048): # use default
> Last sector, +/-sectors or +/-size{K,M,G,T,P} (2050048-1048575966, default 1048575966): +8G

# Set the type SWAP
t
> Partition type or alias (type L to list all): swap # Linux swap

# Change partition name to cryptoswap
# Enter extra functionality mode
x

# Change the partition name
n
Partition number (1-3, default 3): 3
New name: cryptswap

# Return to the main menu
r

# Create a fourth partition (partition for /)
n
> Partition number (4-128, default 4): # use default
> First sector (10242048-1048575966, default 10242048): # use default
> Last sector, +/-sectors or +/-size{K,M,G,T,P} (10242048-1048575966, default 1048575966): # use default

# Change the partition name
n
Partition number (1-4, default 4): 4
New name: cryptsystem

# Return to the main menu
r

# Check partitions, should have two 1G partitions, one 8G partition and one
# partition with the remaining space. The first partition should be EFI, the
# second and fourth should be Linux filesystem and the third should be SWAP
p

# Write the partition table and exit fdisk
w

# List disks (should be same output as we got before in the fdisk prompt (when
# used the command "p" before "w"))
fdisk -l
```

### Encrypt the partition

```sh
# Encrypt the root partition
cryptsetup luksFormat --type=luks2 /dev/sda4

# Open the encrypted partition
cryptsetup open --type=luks2 /dev/sda4 system

# Open swap as crypt device
cryptsetup open --type plain --key-file /dev/urandom /dev/sda3 swap
```

### Configure swap

```sh
# Format the swap partition
mkswap -L swap /dev/mapper/swap

# Enable the swap partition
swapon -L swap
```

### Create the filesystems

```sh
# Create the EFI filesystem
mkfs.fat -F32 /dev/sda1

# Create the /boot filesystem
mkfs.ext4 /dev/sda2

# Create the root filesystem
# mkfs.btrfs /dev/mapper/system
mkfs.btrfs -L system /dev/mapper/system
```

### Configure the BTRFS subvolumes

```sh
# Mount the root filesystem
mount -t btrfs LABEL=system /mnt

# Create the root subvolume
btrfs subvolume create /mnt/@root

# Create the home subvolume
btrfs subvolume create /mnt/@home

# Create the var subvolume
btrfs subvolume create /mnt/@var

# Create the tmp subvolume
btrfs subvolume create /mnt/@tmp

# Create the snapshots subvolume
btrfs subvolume create /mnt/@snapshots

# Unmount the root filesystem
umount -R /mnt
```

### Mounting the subvolumes and partitions

```sh
# Mount the root subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root LABEL=system /mnt

# Mount the snapshots subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@snapshots LABEL=system /mnt/.snapshots

# Mount the var subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@var LABEL=system /mnt/var

# Mount the tmp subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@tmp LABEL=system /mnt/tmp

# Mount the home subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@home LABEL=system /mnt/home

# Mount the boot partition
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
```

### Setting up fstab file

Create the fstab with the current mount points:

```sh
# Creating etc directory
mkdir /mnt/etc

# Generating fstab file
genfstab -U -p /mnt >> /mnt/etc/fstab
```

## Installing Arch Linux

### Base packages

Install base packages for Arch Linux:

```sh
# Install only the base packages
pacstrap /mnt base
```

### Configure swap encryption

Configure crypttab to encrypt the swap partition:

```sh
# Get PARTUUID of the swap partition (remember that /dev/sda3 is the swap partition)
blkid /dev/sda3

# Open the crypttab file
nvim /mnt/etc/crypttab

# Add the swap partition to the crypttab file
swap PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX /dev/urandom swap,offset=2048,cipher=aes-xts-plain64,size=256
```

Verify if swap is correct in fstab:

```sh
# /dev/mapper/swap LABEL=swap
/dev/mapper/swap none swap defaults 0 0
```

Observation: although I'm using UUID for most things, the swap partition I was
only able to make it work with the `/dev/mapper/swap` path.

### Install additional packages

Configure installation through chroot environment:

```sh
# Attach to work in progress installation in chroot environment
arch-chroot /mnt

# linux linux-headers: install kernel latest and lts
# linux-firmware: firmware for the kernel
# nvim: a text editor (nvim, vim, neovim...)
# base-devel is a group of development packages that is often needed
# openssh allows you to use ssh to manage the installation remotely
# networkmanager: network support and wifi support
# btrfs, lvm, ntfs-3g: support to filesystems
# zsh: my preferred shell
pacman -S linux linux-headers \
          linux-lts linux-lts-headers \
          mkinitcpio \
          linux-firmware \
          neovim \
          base-devel openssh \
          networkmanager \
          btrfs-progs lvm2 ntfs-3g \
          zsh zsh-completions

# Enabling ssh service (if you want to manage the installation remotely)
systemctl enable sshd

# Enabling network manager
systemctl enable NetworkManager
```

### Configuring mkinitcpio

Edit the mkinitcpio configuration (`/etc/mkinitcpio.conf`) file to add `encrypt`
and `btrfs` to the `HOOKS` array (before `filesystems`):

```sh
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck)
```

Generate the initramfs:

```sh
mkinitcpio -P
```

### Configuring locale

Edit the /etc/locale.gen and uncomment the desired locales.

```sh
...
#en_SG.UTF-8 UTF-8
#en_SG ISO-8859-1
en_US.UTF-8 UTF-8
#en_US ISO-8859-1
#en_ZA.UTF-8 UTF-8
...
#pl_PL ISO-8859-2
#ps_AF UTF-8
pt_BR.UTF-8 UTF-8
#pt_BR ISO-8859-1
#pt_PT.UTF-8 UTF-8
...
```

Generate the locales:

```sh
locale-gen
```

### Setting users and passwords

#### Set a secure password for root user

```sh
# execute as root user...
passwd
```

#### Create an user account

```sh
useradd -m -U -G wheel,users --shell /usr/bin/zsh <user_name>
passwd <user_name>
```

#### Install sudo if not installed

```sh
pacman -S sudo
```

#### Associating the wheel group with sudo

Open the sudoers file using visudo, you can force nvim putting EDITOR=nvim in
front of the visudo command:

```sh
# Open sudoers file in nvim
EDITOR=nvim visudo
```

Uncomment the line `%wheel ALL=(ALL) ALL` and save the file:

```sh
## Uncomment to allow member of group wheel to execute any command
%wheel ALL=(ALL) ALL
```

## Installing GRUB

Install GRUB, tools and UEFI support:

```sh
pacman -S grub grub-btrfs efibootmgr dosfstools os-prober mtools
```

Creating EFI directory for GRUB and mounting the EFI partition on the new
directory:

```sh
# Creating EFI directory
mkdir /boot/EFI

# Mounting first partition on /boot/EFI (remember to check the partition, it
# should be the EFI partition, in this case, /dev/sda1)
mount /dev/sda1 /boot/EFI
```

Installing GRUB on the master boot record:

```sh
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
```

Setting GRUB locale/language ([1:24:02](https://youtu.be/DPLnBPM4DhI?t=5042)):

```sh
# Check if locale folder exists in /boot/grub
ls -l /boot/grub

# If it doesn't exist, create it
mkdir /boot/grub/locale

# Copy grub locale file from /usr/share/locale to /boot/grub/locale
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
```

Edit the `/etc/default/grub` file to add/set the encryption settings:

```sh
# Opening default grub config file with nvim
nvim /etc/default/grub
```

Uncomment the line `GRUB_ENABLE_CRYPTODISK=y`:

```sh
# Uncomment to enable booting from LUKS encrypted disks
GRUB_ENABLE_CRYPTODISK=y
```

### Search other operational systems

If you want that grub search for other operational systems, you can also
uncomment the line `GRUB_DISABLE_OS_PROBER=false`:

```sh
GRUB_DISABLE_OS_PROBER=false
```

### Remember last selected entry

If you want that grub remember the last selected entry, you can also uncomment
the line `GRUB_SAVEDEFAULT=true` and change the line `GRUB_DEFAULT=0` to
`GRUB_DEFAULT=saved`:

```sh
...
GRUB_DEFAULT=saved
...
GRUB_SAVEDEFAULT=true
...
```

Edit the line with `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"` adding the
parameters
`cryptdevice=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX:system:allow-discards`
before the "loglevel" (UUID is the one from the encrypted partition):

```sh
# get the UUID of the encrypted partition
blkid /dev/sda4

# Example:
GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX:system:allow-discards loglevel=3 quiet"
```

Generate the grub configuration file:

```sh
grub-mkconfig -o /boot/grub/grub.cfg
```

Exiting chroot and rebooting:

```sh
# Exiting chroot
exit

# Unmounting all partitions
umount -a

# Reboot the system
reboot
```

## Post-install Tweaks

Boot the system and log as the user that was created.

Most commands require root privileges, so you can use `sudo` before each command
or use `su` to become root.

```sh
su
```

### Timezone, Locale and Time Sync

#### Setting up timezone

```sh
# Check for available timezones
timedatectl list-timezones

# Set timezone to your location (America/Sao_Paulo for me)
timedatectl set-timezone America/Sao_Paulo
```

#### Enabling services for time sync

Enabling systemd-timesyncd service so that the system syncs the time at start

```sh
# Sync time at start
systemctl enable systemd-timesyncd
```

### Hostname and Hosts File

#### Set machine hostname

```sh
# File /etc/hostname probably doesn't exists yet
cat /etc/hostname

# Set hostname as a name of your choice
hostnamectl set-hostname <hostname>

# Now the file /etc/hostname was generated
cat /etc/hostname
```

#### Editting the hosts file

Open the file `/etc/hosts`:

```sh
nvim /etc/hosts
```

Add the following lines to the file:

```sh
127.0.0.1 localhost
127.0.1.1 <hostname>
```

Observation: Use the name chosen as hostname instead of `<hostname>`.

### Installing Micro Code For CPU

Install micro code for AMD or Intel CPU so that the system can take advantage of
the latest CPU features and security updates.

For AMD CPU:

```sh
pacman -S amd-ucode
```

For Intel CPU:

```sh
pacman -S intel-ucode
```

### Installing Xorg and GPU Drivers

Install xorg and gpu drivers (no wayland yet... I like awesome wm too much and I
am too lazy to update my config and scripts to work with wayland):

```sh
# If you have an intel or amd GPU, install the mesa package
pacman -S mesa

# If you have a nvidia GPU, install the nvidia or nvidia-lts packages (or both)
pacman -S nvidia nvidia-lts

# Installing xorg
pacman -S xorg-server
```

### Pacman configuration

#### Enable multilib

Enabling multilib (required for some packages, like `steam` for example)
([arch wiki reference](https://wiki.archlinux.org/title/official_repositories#Enabling_multilib)):

Uncomment section `[multilib]` in `/etc/pacman.conf`:

```sh
[multilib]
Include = /etc/pacman.d/mirrolist
```

#### Optimize downloads

```sh
# Enable this option to enable parallel downloads
ParallelDownloads = 5

```

#### Customize output

```sh
# Enable this option to enable color output
Color

# Add this secret option to make pacman output more visually appealing
ILoveCandy
```

### Package manager for AUR

Yay is a wrapper for pacman that allows you to install packages from the AUR.
The syntax is similar to pacman, so it's easy to use.

Obs.: Use those commands as normal user, not as root.

```sh
# Essential dependencies
pacman -S base-devel git

# Clone yay repository
git clone https://aur.archlinux.org/yay.git

# Enter the directory
cd yay

# Build and install the package
# Observation: in the guide, he uses only `makepkg -s`, but for me it only works with `makepkg -si`
makepkg -si
```

### Numlock at early boot (mkinitcpio)

Activating numlock at early boot (if the password has numbers, it can be useful)
([arch wiki reference](<https://wiki.archlinux.org/title/Activating_numlock_on_bootup#Early_bootup_(mkinitcpio)>)):

```sh
# Install AUR package mkinitcpio-numlock
yay -S mkinitcpio-numlock

# Edit the file `/etc/mkinitcpio.conf`
nvim /etc/mkinitcpio.conf
```

In the line `HOOKS=(...` move `keyboard` to before `modconf`, and add `keymap`,
`consolefont` and `numlock` after keyboard. Example:

```sh
HOOKS=(base udev autodetect keyboard keymap consolefont numlock modconf block encrypt btrfs filesystems fsck)
```

#### Locale.conf With Fallback

My locale.conf file with fallback
([arch wiki reference](https://wiki.archlinux.org/title/locale#LANGUAGE:_fallback_locales)):

```sh
LANG="en_US.UTF-8"
LANGUAGE="en_US:en:C:pt_BR"
LC_ADDRESS="pt_BR.UTF-8"
LC_COLLATE="pt_BR.UTF-8"
LC_CTYPE="pt_BR.UTF-8"
LC_IDENTIFICATION="pt_BR.UTF-8"
LC_MEASUREMENT="pt_BR.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="pt_BR.UTF-8"
LC_NAME="pt_BR.UTF-8"
LC_NUMERIC="pt_BR.UTF-8"
LC_PAPER="pt_BR.UTF-8"
LC_TELEPHONE="pt_BR.UTF-8"
LC_TIME="pt_BR.UTF-8"
```

### Configure XDG directories

Edit the `/etc/security/pam_env.conf` to set the XDG directories:

Add the following lines to the file:

```sh
XDG_CONFIG_HOME DEFAULT=@{HOME}/.config
XDG_DATA_HOME   DEFAULT=@{HOME}/.local/share
XDG_STATE_HOME  DEFAULT=@{HOME}/.local/state
XDG_CACHE_HOME  DEFAULT=@{HOME}/.cache
```

ps: Some directories may not exist yet, so use `mkdir` just in case.

```sh
mkdir -p ~/.config
mkdir -p ~/.local/share
mkdir -p ~/.local/state
mkdir -p ~/.cache
```

### Configuring ZDOTDIR

Edit the `/etc/zsh/zshenv` to set the ZDOTDIR:

Add the following lines to the file:

```sh
ZDOTDIR=$HOME/.config/zsh
```

## Installing AwesomeWM

### AwesomeWM installation

Install awesome wm package

```sh
pacman -S awesome
```

Copy the default configuration to the user directory:

```sh
mkdir ~/.config/awesome
cp /etc/xdg/awesome/rc.lua ~/.config/awesome/rc.lua
```

Edit the `rc.lua` file to set the default terminal emulator to alacritty:

```sh
nvim ~/.config/awesome/rc.lua
```

Find the line `terminal = "xterm"` and change it to `terminal = "alacritty"`.

### Window manager and login manager

Install a login manager (I use lightdm) and a terminal emulator (I use
alacritty):

```sh
pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

Enable the lightdm service:

```sh
systemctl enable lightdm
```

### Basic applications for a desktop environment

Firefox: web browser PCManFM: file manager Alacritty: terminal emulator
PipeWire: audio server

```sh
pacman -S firefox pcmanfm-gtk3 alacritty pipewire pipewire-pulse pipewire-jack
```

Enable user services for pipewire:

```sh
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
```

### Persist keyboard layout

```sh
sudo setxkbmap -layout br -variant abnt2
```

### Install flatpak

```sh
pacman -S flatpak xdg-desktop-portal xdg-desktop-portal-gtk
```

## BTRFS snapshots

### Create first snapshot (clean install)

```sh
btrfs subvolume snapshot / /.snapshots/@clean-install
```

### Pacman hook for snapshots

Create a pacman hook to create a snapshot before and after a system upgrade
([arch wiki reference](https://wiki.archlinux.org/title/pacman#Hooks)):

```sh
# Create the directory for the pacman hooks
mkdir /etc/pacman.d/hooks

# Create the file for the pacman hook
nvim /etc/pacman.d/hooks/90-btrfs-snapshot.hook
```

Add the following lines to the file:

```sh
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Operation = Remove
Target = linux
Target = linux-lts
Target = nvidia
Target = nvidia-lts
Target = intel-ucode
Target = grub

[Action]
Description = Creating BTRFS snapshot before system upgrade
When = PreTransaction
Exec = /usr/bin/bash -c '/usr/bin/btrfs subvolume snapshot / /.snapshots/@root-snapshot-$(date +%Y-%m-%d-%H-%M)'
AbortOnFail
```

### Pacman hook for grub update

Create another pacman hook to update the grub configuration file after a system
upgrade:

```sh
# Create the file for the pacman hook
nvim /etc/pacman.d/hooks/91-grub-mkconfig.hook
```

Add the following lines to the file:

```sh
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Operation = Remove
Target = linux
Target = linux-lts
Target = nvidia
Target = nvidia-lts
Target = intel-ucode
Target = grub

[Action]
Description = Update grub cfg so it can boot from new snapshots
When = PostTransaction
Exec = /usr/bin/bash -c '/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg'
```

### Restoring a snapshot

Very important! I never actually needed this, I just tested once to see if it
worked, but I never had to use it in practice and I'm not sure if this is the
correct way to do it...

1. Boot from a snapshot using grub-btrfs.

2. Do the following steps:

```sh
# list btrfs subvolumes
btrfs subvolume list /

# boot the desired snapshot to restore
mount -t btrfs -o subvolid=<subvol_id> /dev/mapper/system /mnt

# to check mounted btfrs subvolumes you can use findmnt
findmnt -t btrfs

# edit the fstab file to change the id of the root subvolume
nvim /mnt/etc/fstab
# UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx / btrfs rs,noatime,compress=zstd,ssd,space_cache,subvolid=256,subvol=@root 0 0
# =>
# UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx / btrfs rs,noatime,compress=zstd,ssd,space_cache,subvolid=<NEW_ID>,subvol=@root 0 0

# Unmount the root filesystem
umount -R /mnt

# mount subvolid 5 in some directory
mount -t btrfs -o subvolid=5 /dev/mapper/system /mnt

# go to the mounted directory
cd /mnt

# rename @root to @root.bak
mv @root @root.bak

# rename @snapshots/@root-snapshot-2021-09-01-00-00 to @root
mv @snapshots/@root-snapshot-2021-09-01-00-00 @root

# umount the filesystem
umount /mnt

reboot
```

## Customizations

This is a simple install, it is a good idea to give a look into
[archwiki "General recommendations"](https://wiki.archlinux.org/title/general_recommendations)
and
[archwiki "Improving performance"](https://wiki.archlinux.org/title/Improving_performance).

Besides that, now it is just a matter of customizing the system to your needs.
:)

## References

- Most of what I know came from the "arch linux installation guides" from
  [Learn Linux TV](https://www.youtube.com/@LearnLinuxTV) and the
  [Arch Linux Wiki](https://wiki.archlinux.org/).
- While researching some steps that I didn't remember from the last time I
  installed arch like this, I found the following guide
  [User:ZachHilman/Installation - Btrfs + LUKS2 + Secure Boot](https://wiki.archlinux.org/title/User:ZachHilman/Installation_-_Btrfs_%2B_LUKS2_%2B_Secure_Boot),
  which has some cool steps that I hadn't done before, like encrypting the swap
  partition, so I ended up using it as a reference for some steps.
- My old notes (it is kinda outdated, but I believe it still works):
  [Arch install with UEFI and Encryption](https://gist.github.com/WELL1NGTON/d456e65bc1e09e487aa1e421be72a7dc)
