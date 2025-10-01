# BreadfanOS
An operating system project built from scratch in x86 assembly.

## Current Status
Bootable kernel with:
- ✅ Working shell with multiple commands
- ✅ Persistent file system (directory only)
- ✅ Calculator with expression parsing
- ✅ Screen scrolling
- ✅ Disk I/O to separate drive

## Building and Running

Use the provided build script:
```bash
./build/makeimage.sh

Manual Build (if needed)
bashnasm -f bin kernel.asm -o kernel.bin
nasm -f bin bootloader.asm -o bootloader.bin
cp bootloader.bin breadfanos.img
cat kernel.bin >> breadfanos.img
dd if=/dev/zero bs=1024 count=1440 >> breadfanos.img 2>/dev/null
qemu-system-i386 -drive file=breadfanos.img,format=raw -drive file=harddisk.img,format=raw -k en-gb

##Requirements

NASM assembler
QEMU (qemu-system-i386)
A persistent hard disk image (harddisk.img) - created automatically on first disk write

##Development Goal
Building toward a simple compiler by first implementing:

File content storage (next)
Program loader
System call interface
Memory managemen
