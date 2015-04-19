@echo off

rem build.bat

rem WARNING: link.exe is only for 32-bit Windows which can run 16-bit programs.
rem C:\L\JWlink_v19b11_win32\jwlink.exe is from http://www.japheth.de/JWlink.html
rem build.sh + Makefile is the preferred way to build
rem  (e.g. "ub14-vm ubuntu-14.04-desktop-amd64.iso" under VMware Workstation 10).


set NASMFLAGS=-O0


gawk -f asap.awk < common-asap.nasm > common.nasm

gawk -f asap.awk < init-asap.nasm > init.nasm
sh do-version.sh .
nasm -f bin %NASMFLAGS% -l init.lst init.nasm -o init.img
rem nasm -f elf -g -l init.lst init.nasm -o init.elf
rem objcopy -O binary init.elf init.objcopy.img

cat init.img > bootmtrr.img


rem copy bootmtrr.img \\bun\bootmtrr\
