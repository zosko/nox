# nox
Simple Floppy bootable thing

# Install
 - `brew install dosfstools`
 - `brew install nasm`
 - `brew install qemu`

# Commands to make bootable floppy

- `nasm boot.asm -f bin -o boot.img`
- `dd if=/dev/zero of=floppy.img bs=512 count=2880`
- `/usr/local/Cellar/dosfstools/4.2/sbin/mkfs.fat -F 12 -n "Nox" floppy.img`
- `dd if=boot.img of=floppy.img conv=notrunc`

 ## Command to test in emulator
 
 - `qemu-system-i386 -fda floppy.img`
