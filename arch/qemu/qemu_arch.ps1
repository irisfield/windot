$qemu = "${env:ProgramFiles}\qemu\qemu-system-x86_64.exe"

& $qemu -accel tcg -m 4G -smp 4 -hda arch.vhdx -vga qxl -usb -usbdevice tablet -cdrom archlinux-2024.06.01-x86_64.iso -boot d
