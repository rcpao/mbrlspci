README for mbrlspci ----------------------------------------------------------

mbrlspci is a Legacy MBR (with no partition table entries) for reading
PCI Configuration registers for test purposes.

Copyright (C) 2015 Roger C. Pao <rcpao1+mbrlspci@gmail.com>

Sun Apr 19 01:21:30 PDT 2015


License (GPLv3) --------------------------------------------------------------

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3 as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


Build Tools ------------------------------------------------------------------

The Netwide Assembler (NASM) multi-platform assembler
	http://www.nasm.us/

JWlink multi-platform linker
	http://www.japheth.de/JWlink.html

Cygwin http://www.cygwin.com/ (Windows only)
	sed
	gawk
	make
	gdb (for debugging)

TortoiseSVN command line utilities (Windows only)
	svn
	svnversion

Linux (e.g. Ubuntu 12.04+, Fedora 16+, ...)
	See Linux Build Procedure below.

Windows 2000 Professional
Windows 7 64-bit (cannot run 16-bit programs)
	See Windows Build Procedure below.


Buildbot Procedure -----------------------------------------------------------

This is a test program.  There is no need for buildbot to build this.


Windows Build Procedure ------------------------------------------------------

1. git clone TBD
2. build.bat
   or
   make.exe [spotless | all] (uses Makefile)
3. mbrlspci.img is the output file to be written to LBA 0 (MBR) of 
   the Legacy BIOS boot drive.  This requires Windows specific programming
   so Linux is the preferred development environment.


Linux Build Procedure --------------------------------------------------------

1. git clone TBD
2. cd ~/Documents/mbrlspci
3. ./build.sh
4. ./mbrlspci.img is written to Legacy BIOS boot drives hardcoded
   in updatembrlspci.sh depending on $HOSTNAME.
5. ./mbrlspci.img is copied to the following:
   pixi as /var/lib/tftpboot/mbrlspci/mbrlspci-{svn_revision}.img

./updatembrlspci.sh is hard coded for specific hosts to do the following:
1. Write the *.img file to /dev/sd#, the boot pdisk in mbrlspci VM, 
   for testing.
2. Copy *.exe files to FreeDOS 1.1 test 3 VM for testing. [obsolete]
3. Write the *.img file to 
   /dev/disk/by-id/ata-KINGSTON_SSDNOW_30GB_20BM10B2M83Z (unique per test drive), 
   a mbrlspci pdisk with Toshiba SATA to USB adapter, for testing in
   a physical test system such as the Tyan S5512.

The FQDN is hard coded in updatembrlspci.sh to prevent other build
environments with different /dev/sd# device mapping to ddmbrlspci.img
the wrong drives.  You may add additional FQDN/ddmbrlspci.img lines to
updatembrlspci.sh as needed.

updatembrlspci function overwrites the MBR with mbrlspci.img but preserves the 
UEFI disk signature and existing partitions.


Serial port debug output can be redirected in VMware settings for the VM.
ERROR: Apparently, MBR runtime does not redirect serial port output in VMware 
       while it works in Tyan S5512.

WARNING: All three VMs share some of the same *.vmdk disk images.
         Make sure only one of these VMs is powered on at a time.

ERROR: nasm does not generate CodeView debug information.

ERROR: VMware Workstation 9 with Windows 2000 Professional guest without 
       VMware Tools will NOT have working virtual serial ports for either 
       output file or named pipe "\\.\pipe\w2k_com1".


VMware Workstation 9.0 Debug Environment -------------------------------------

Sorry, no source level debugging and no symbols will be available.
gdb is expecting ELF formatting and probably does not allow symbol relocation anyway the way
Soft-ICE msym.exe and symloc does.

Add the following four lines to "C:\Users\develop1\Documents\Virtual Machines\VMware ESXi 5.1.0 enahci monitor.debugOnStartGuest32=_TRUE_\VMware ESXi 5.1.0 enahci monitor.debugOnStartGuest32=_TRUE_.vmx"
debugStub.hideBreakpoints = "TRUE"
debugStub.listen.guest32 = "TRUE"
debugStub.listen.guest32.remote = "TRUE"
monitor.debugOnStartGuest32 = "TRUE"

Virtual Machine Settings > Hardware > [Add...]
Serial Port
Output to file
Output file: serial1.txt
[x] Connect at power on
The specified path "...\serial1.txt" does not exist.
Would you like to keep this setting anyway? [Yes]

> Power on this virtual machine

The virtual machine console will remain black until gdb connects and tells the CPU to continue.
cygwin/gdb must be run from the same system running VMware Workstation.
gdb will not connect from a VMware Workstation guest.
[Perhaps some more settings might make it work in a VMware Workstation guest, but 
once I got it working, I stopped tinkering with the debugging environment.]
Serial Port to output file serial1.txt works from VMware ESXi guest VM; however,
  it does not work in Win7 guest VM.  I believe it expects a Win application to open the VMware Tools'
  serial device driver while we hammer the hardware I/O ports directly before Win7 even starts.

Cygwin Terminal

develop1@roger ~
$ gdb
GNU gdb (GDB) 7.6.50.20130728-cvs (cygwin-special)
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "i686-pc-cygwin".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word".

(gdb) target remote localhost:8832
Remote debugging using localhost:8832
0xfffffff0 in ?? ()
(gdb) set arch i8086
warning: A handler for the OS ABI "Cygwin" is not built into this configuration
of GDB.  Attempting to continue with the default i8086 settings.

The target architecture is assumed to be i8086
(gdb) c
Continuing.
[New Thread 2]

Program received signal SIGINT, Interrupt.
[Switching to Thread 2]
0x00012000 in ?? ()
(gdb) c
Continuing.

Some useful gdb commands (but google is your friend):
target remote localhost:8832
set arch i8086
break *0x7c00
disas 0x7c00,0x7e00
x/128xb 0x79d
break *0x600
break *0x6a9
break *0xda5
info breakpoints (i b)
info reg (i r)
c
si


Configuration Variables ------------------------------------------------------

Configuration variables are located at fixed offsets in mbrlspci.img.
Use a hex editor such as hexedit in Linux or frhed or HxD in Windows.

Offset	Description
1B0	VerboseLevel (default = 07h)
1B1	DbgLevel (default = 00h)
	00h = None
	05h = Press any key to continue
	see common.ninc for various DL_## values
	FEh = Maximum
1B2	DbgComIoBase (least significant byte) (default = 00h)
1B3	DbgComIoBase (most significant byte) (default = 00h)
1B4	Unused (00h)
1B5	Unused (0FFh)
1B6	Unused (00h)
1B7	Unused (00h)
1B8	UEFI disk signature (4 bytes) (if 0, Tyan S5512 EFI BIOS will write
	a random number in.  Windows 7+ will as well.)
1BC	UEFI 0000h

All multiple byte values are little-endian byte order (least significant byte first).

Serial port debug output information:

DbgComIoBase = 
000h Disabled
3F8h COM1
2F8h COM2

Use a null modem cable to 115200 bps, 8, None, 1, Hardware flow control (RTS specifically) 
must be asserted to enable serial output.

Example:

000001B0   07 05 F8 03  00 FF 00 00  00 00 00 00  00 00 00 00  ................

VerboseLevel = 7
DbgLevel = 05h
DbgComIoBase = 3F8h (COM1 base I/O port)


Notes ------------------------------------------------------------------------

. init-asap.nasm/{VerboseLevel,DbgLevel,DbgComIoBase,...}
  configuration variables can be patched with a sector editor before booting.

. Serial port output will not look as pretty as console output.
BackSpaces in PuTTY will line wrap backwards to the previous line while 
console output will remain at the far left column of the current line.


Pending List (TBD) -----------------------------------------------------------

. Simple checksum mbrlspci sectors against short_image/corruption.
Be aware that changing the Dbg* locations, UEFI disk signature, or partition tables 
will require recalculating the checksum or do not include them in the checksum.
d PrChecksum1 is implemented only for manual debug monitoring.

d Win8 installation requires some post-processing by mbrlspci before loading 
the Win8 boot sector.

x Only CONV(entional) memory is working.  EBDA is apparently broken.
WARNING: If EBDA moves after our 
crash on the next INT 13h request.
wont fix

x DOS .COM version for Soft-ICE trace through Win8 boot sector?
wont fix

. Windows Setup:
Windows cannot be installed to this disk.  
This computer's hardware may not support booting to this disk.  
Ensure that the disk's controller is enabled in the computer's BIOS menu.

. MS-DOS 6.22 fails
FreeDOS 1.1 fails
ESXi 5.1.0 boots
ESXi 5.5.0 boots
Win7 boots
Win8.0 boots

. EDD-4 INT 13h DAP support of 64-bit extensions
Can the Intel 64-bit motherboard do INT 13h beyond the 32 MBs limit?

x Greater than 512 byte sector size?
Are there any legacy bootloaders that can boot > 512 byte sectors?
Probably best continue with UEFI.
wont fix

x Must detect if we have already allocated EBDA or conventional memory and avoid 
re-allocating and re-hooking INT 13h again on restart (most likely from INT 18h).
wont fix
mbrlspci currently only uses conventional memory.


Legend:
. tbd
t testing required
x wont fix
d testing done
