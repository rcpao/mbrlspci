#!/bin/bash


# Prerequisites
# sudo apt-get install qemu-system-x86


# http://blog.oldcomputerjunk.net/2013/debugging-an-x86-bootloader-using-qemukvm/


cd ~/Documents/mbrlspci/qemu-dbg

# PASS
qemu-system-x86_64 -boot c -m 256 -enable-kvm -hda hda-contents/mbrlspci.img -no-acpi &


# FAIL
# qemu-system-x86_64 -boot c -m 256 -enable-kvm -hda hda-contents/mbrlspci.img -no-acpi -s -S
# gdb -x gdb-script.txt


# UEFI OVMF (not for Legacy MBRs)
# qemu-system-x86_64 -bios ./bios.bin -hda fat:hda-contents -debugcon file:debug.log -global isa-debugcon.iobase=0x402
