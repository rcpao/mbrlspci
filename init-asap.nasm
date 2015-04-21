;-----------------------------------------------------------------------------
;init-asap.nasm -- mbrlspci Master Boot Record
;
;Scan PCI adapters for Legacy BIOS (and UEFI with CSM) booting
;
;
;References:
;  http://www.nasm.us/
;  http://stackoverflow.com/questions/10598802/which-value-should-be-used-for-sp-for-booting-process
;  http://en.wikipedia.org/wiki/Master_boot_record
;  http://en.wikipedia.org/wiki/Volume_Boot_Record
;  http://en.wikipedia.org/wiki/BIOS_parameter_block
;  http://stackoverflow.com/questions/10598802/which-value-should-be-used-for-sp-for-booting-process
;  http://www.organicdesign.co.nz/Writing_a_boot_loader_in_assembler
;  BIOS Boot Specification Version 1.01
;  oxpcie952_ds.pdf, OXPCIe952 PCI Express Bridge to Dual Serial & Parallel Port
;  OXPCIe952.pdf, OXPCIe952 Data Sheet, April 15 2009
;  Roger C. Pao <rcpao1+mbrlspci@gmail.com>
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;Include Files
;-----------------------------------------------------------------------------

USE_common_asap_nasm	equ	1 ;0 or 1
%include "common.ninc"


;-----------------------------------------------------------------------------
;Defines
;-----------------------------------------------------------------------------

;PERM_* variables in Init in the absence of Perm.
;%define PERM(x)		[es:PERM_ %+ x %+ ]
%define PERM(x)		[cs: %+ x %+ ]


VL_STEPS_TYPE		equ	4 ;PrVlStep characters displayed
				  ;2 = 01,02,03,...
				  ;4 = 0x__LINE__


;-----------------------------------------------------------------------------
;Macros
;  Not all macros are defined here.
;  There are other macros sprinkled throughout this file.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;INIT_LINE __LINE__, "init line description"
;  Update [cs:InitLineNumber] in case of jc .Err*.
;  "init line description" is a comment and is not compiled in
;Input
;  Line number from __LINE__
;Output
;  None
;Modifies
;  None
;-----------------------------------------------------------------------------
;InitLineNumber:	dw	0		;Use INIT_LINE to update
%macro INIT_LINE 2+ ;__LINE__ ;"init line description"
%if 1
		mov	word [cs:InitLineNumber], %1
%else
		pushf
		push	ax

		mov	ax, %1		;eax = __LINE__
		mov	[cs:InitLineNumber], ax

		pop	ax
		popf
%endif
%endmacro ;INIT_LINE


;-----------------------------------------------------------------------------
;_CALL_FAR_PERM_PREV_INT13H
;-----------------------------------------------------------------------------
%macro _CALL_FAR_PERM_PREV_INT13H 0
		pushf				;Simulate INT 13h to PERM(PREV_INT13H)
		call far PERM(PREV_INT13H)	;
		;add	sp, 2			;PERM(PREV_INT13H)'s iret will popf
%endmacro ;_CALL_FAR_PERM_PREV_INT13H


;-----------------------------------------------------------------------------
;_CALL_INT13H
;-----------------------------------------------------------------------------
%macro _CALL_INT13H 0
		int	13h
%endmacro ;_CALL_INT13H


;-----------------------------------------------------------------------------
;DBG_PR_INIT_DAP
;  InitDAP, InitInt13hRetryMax, InitInt13hRetryLimitValue
;-----------------------------------------------------------------------------
%macro DBG_PR_INIT_DAP 2+
%if ((DBG_ENABLED) && (USE_common_asap_nasm))
		pushf
		cmp	byte [cs:DbgLevel], %1
		jb	%%Ldone

		PR_STR %2

		call	PrInitDap

%%Ldone:
		popf
%endif ;DBG_ENABLED
%endmacro ;DBG_PR_INIT_DAP


;-----------------------------------------------------------------------------
;Master Boot Record (MBR) at LBA0
;
;Input
;  dl = boot drive number (usually 80h, but BBS allows others)
;Output
;  none
;Modifies
;  all
;
;Calls INT 18h if boot fails per BBS Appendix D.2.
;-----------------------------------------------------------------------------
		[BITS 16]
		[map all init-asap.map]
%if (BUILD_TYPE == BUILD_TYPE_MBR)	;MBR boot loader
		section	Init progbits
		org	600h
InitOrg:
%elif (BUILD_TYPE == BUILD_TYPE_COM)	;DOS .COM file for testing
		section	Init
		org	100h
InitOrg:
		jmp	Stage1
%elif (BUILD_TYPE == BUILD_TYPE_EXEBIN)	;DOS .EXE file for testing
not implemented
%include "exebin.mac"
		EXE_begin
		EXE_stack 800h
		section	.text
InitOrg:
		jmp	Stage1
%endif
_start:
Mbr:
Bootstrap1:

		;mbr.S is not to be used as a volume boot record (VBR),
		;so BIOS parameter block (BPB) is not defined in here at 
		;0x000B to 0x0036 + 8


;This comment section is obsolete and only remains for historical purposes.
;
;Relocate to 0:0600 per
;http://stackoverflow.com/questions/10598802/which-value-should-be-used-for-sp-for-booting-process
;and recommended by 
;http://wiki.osdev.org/Rolling_Your_Own_Bootloader#What_if_I_wish_to_offer_the_user_the_option_to_boot_several_OSes_.3F
;Note the org 600h above.


		;int	3		;Does not stop the VMware Workstation gdb remote debugger :(

%if 0 ;Division by zero
		;ERROR: DBG_PR_STR_CRLF/PrStrCS does not exist in MBR!
		DBG_PR_STR_CRLF DL_MAX, "__LINE__ DBG before dividing by zero"
		xor	ax, ax			;Division by zero
		div	al			;
		DBG_PR_STR_CRLF DL_MAX, "__LINE__ DBG after dividing by zero"
		;Tyan SS5512 cursor at top left and beep forever or remain silent.
		;  It appears random if it beeps or is silent.  Keyboard LEDs are frozen.
%endif ;Division by zero

		cli

		;No space in MBR for PrRegs or ComOutAL
		;No addresses are valid before .Reloc: so we cannot save registers yet.

		;Stack from 0:7C00h growing downward toward our code starting at 0600h
		xor	sp, sp		;sp = 0
		mov	ss, sp		;ss = 0
		mov	sp, 7C00h	;sp = 7C00h

		push	ax
		push	cx
		push	si
		push	di
		push	ds
		push	es

		xor	cx, cx		;cx = 0
		mov	ds, cx		;ds = 0
		mov	es, cx		;es = 0

		;Relocate us to 0:600h
		mov	si, 7C00h	;ds:si = source
		mov	di, 0600h	;es:di = destination
		mov	cx, (512 / 2)	;byte to word adjust
		rep	movsw		;copy source to destination for cx words
		
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	cx
		pop	ax

		;Make sure we are at 0000:0600+here
		jmp	0:.Reloc	;Force cs to 0
.Reloc:				;

		push	2		;clear all flags bits off
		popf   			;


%if SAVE_INIT_REGS
		;Warning: cs must be 0 here as Entry* are org 600h.
		mov	[cs:EntryEAX], eax
		mov	[cs:EntryEBX], ebx
		mov	[cs:EntryECX], ecx
		mov	[cs:EntryEDX], edx
		mov	[cs:EntryESI], esi
		mov	[cs:EntryEDI], edi
		mov	ax, ds
		mov	[cs:EntryDS], ax
		mov	ax, es
		mov	[cs:EntryES], ax
%endif ;%if SAVE_INIT_REGS


		xor	ax, ax		;ax = 0
		mov	ds, ax		;ds = 0
		mov	es, ax		;es = 0


		test	byte [cs:VerboseLevel], VL_SIGN_ON
		jz	.SkipMsgSignOn1
		mov	si, MsgSignOn1
		call	PrStrCS1	;Do not call DBG ComOutAL as MBR is too small for serial I/O
.SkipMsgSignOn1:

%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_MBR >= USE_KEY_PAUSE_DBG_MBR)
		push	ax
		push	si
		mov	si, MsgPause
		call	PrStrCS1
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE

%if 0 ;Division by zero
		;ERROR: DBG_PR_STR_CRLF/PrStrCS does not exist in MBR!
		DBG_PR_STR_CRLF DL_MAX, "__LINE__ DBG before dividing by zero"
		xor	ax, ax			;Division by zero
		div	al			;
		DBG_PR_STR_CRLF DL_MAX, "__LINE__ DBG after dividing by zero"
		;Tyan S5512 prints mbrlspci v0.0.3921\r\n*cursor and beep*.  Keyboard LED still toggles.
%endif ;Division by zero

%if 1
		test	byte [cs:VerboseLevel], VL_STEPS
		jz	.SkipMsgLoading
		mov	si, MsgLoading
		call	PrStrCS1
.SkipMsgLoading:
		;call	PrVlDot
%endif


		;-------------------------------------------------------------
		;Check if Extended INT 13h (LBA) is supported
		;-------------------------------------------------------------
		push	dx		;Save dl boot drive number
		mov	ah, INT_13H_EXT_PRESENT_AH
		mov	bx, 055AAh
		int	13h
		pop	dx		;Restore dl boot drive number
		jc	.HangNoInt13hExt
		cmp	bx, 0AA55h
		jne	.HangNoInt13hExt
		

		call	PrVlDot


		;-------------------------------------------------------------
		;Load sectors from boot drive to 0:0600h + 512 and
		; jump there
		;-------------------------------------------------------------
		mov	si, InitDAP	;ds:si=DAP
		mov	word [si + DAP_HOST_XFER_BUF_4B_OFS], 0600h + 200h ;Offset after the MBR
		mov	ah, INT_13H_EXT_READ_AH		;Extended Read
		int	13h
		jc	.HangExtReadErr

		call	PrVlDot


USE_VERIFY_SHORT_READ equ 0 ;Mon Oct  6 10:34:01 PDT 2014 Disabled
	;EDD-4: "In the event of an error, the block count field of the device address
	; packet contains the number of good blocks read before the error occurred."
	;grub-0.97/stage1/stage1.S checks for cf, never checks block field count.
	;grub2-1.99/grub_core/boot/i386/pc/boot.S behaves like GRUB 0.97.
	;Dell Latitude E6400 laptop jumps to .HangShortRead, so we disable this check
	; to match grub behavior.
%if USE_VERIFY_SHORT_READ
		;Verify number of blocks read
		mov	si, InitDAP	;ds:si=DAP
%if (USE_PERM_7C00H)
		cmp	byte [si + DAP_NUM_BLKS_XFER_1B], ((Init_length + 511) / 512) - 1
%else ;USE_PERM_7C00H
		;cmp	byte [si + DAP_NUM_BLKS_XFER_1B], ((Init_end - Init_start + PERMSIZE + 511) / 512) - 1
		cmp	byte [si + DAP_NUM_BLKS_XFER_1B], ((Init_length + PERMSIZE + 511) / 512) - 1
%endif ;USE_PERM_7C00H
		jne	.HangShortRead

		call	PrVlDot
%endif ;USE_VERIFY_SHORT_READ


%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_MBR >= USE_KEY_PAUSE_DBG_MBR)
		push	ax
		push	si
		mov	si, MsgPause
		call	PrStrCS1
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE

		;Registers preserved from entry: dl
		;Registers modified and passed to Stage1: ds=0, es=0
		;Registers destroyed from entry: ax, bx=0AA55h, si=Msg*
		jmp	Stage1
		

		;-------------------------------------------------------------
		;Error Conditions
		;-------------------------------------------------------------
.HangNoInt13hExt:
		mov	si, MsgNoInt13hExt
		call	PrStrCS1
		jmp	.Hang

.HangExtReadErr:
		mov	si, MsgExtReadErr
		call	PrStrCS1
		jmp	.Hang
		
%if USE_VERIFY_SHORT_READ
.HangShortRead:
		mov	si, MsgShortRead
		call	PrStrCS1
		jmp	.Hang
%endif ;USE_VERIFY_SHORT_READ

.Hang:
Hang:		;Error: We cannot boot.  Hang forever.
		mov	si, MsgHang
		call	PrStrCS1
.HangLoop:	jmp	.HangLoop

		
;-----------------------------------------------------------------------------
;PrVlDot
;-----------------------------------------------------------------------------
PrVlDot:	;proc	near
		test	byte [cs:VerboseLevel], VL_STEPS
		jz	.SkipMsgDot
		mov	si, MsgDot
		call	PrStrCS1
.SkipMsgDot:
		ret
;PrVlDot	endp


;-----------------------------------------------------------------------------
;PrStrCS1
;  Write ASCIIZ string.
;  PrStrCS1 procedure is only for MBR use.
;  Stage1 should use PrStrCS instead for serial port debug output.
;Input
;  cs:si = ASCIIZ string to write
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrStrCS1: 	;proc	near
		push	ax
		push	bx
		push	si

.PrStrCsTop:
		mov	al, [cs:si]
		or	al, al
		jz	.PrStrCsDone$

		;call	PrCharAL
		mov	bx, 0001h
		mov	ah, 0Eh
		int	10h

		inc	si
		jmp	.PrStrCsTop

.PrStrCsDone$:
		pop	si
		pop	bx
		pop	ax
		ret
;PrStrCS1	endp


%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_MBR > USE_KEY_PAUSE_DISABLED)

;-----------------------------------------------------------------------------
;KeyGet
;  Check if a key was pressed using Int 16h, AH=01h Keystroke Status.
;  Remove and return the ASCII character code and Scan code if so.
;  This is a non-blocking routine.  It will always immediately return.
;Input
;  None
;Output
;  zf = 1: no key was pressed
;    ax is unmodified
;  zf = 0: a key was pressed
;    al = ASCII character code
;    ah = scan code
;Modifies
;  ax
;  flags
;-----------------------------------------------------------------------------
KeyGet: 	;proc	near
		push	ax
		mov	ah, 01h		;Keystroke Status
		int	16h		;
		pop	ax
		jz	.KeyGetDone$
		pushf			;Save zf=0
		xor	ah, ah		;Keyboard Read
		int	16h		;
		popf			;Restore zf=0
.KeyGetDone$:
		ret
;KeyGet		endp


;-----------------------------------------------------------------------------
;KeyPause
;  * obsolete: Print a prompt to press any key. *
;  Wait forever until a key is pressed.
;  Return the key.
;Input
;  None
;Output
;  zf = 0: a key was pressed
;    al = ASCII character code
;    ah = scan code
;Modifies
;  ax
;  flags
;-----------------------------------------------------------------------------
KeyPause:	;proc	near
		call	KeyGet
		jz	KeyPause
		ret
;KeyPause	endp

%endif ;USE_KEY_PAUSE


;-----------------------------------------------------------------------------
;MBR Data Area
;-----------------------------------------------------------------------------
MsgSignOn1:	db	"mbrlspci v",VERSION_STR,0
%if (USE_KEY_PAUSE > USE_KEY_PAUSE_DISABLED)
MsgPause:	db	CR,LF
MsgErrPauseContinue:
		db	"Press any key to continue",0
%endif ;USE_KEY_PAUSE
MsgCRLF:	db	CR,LF,0
MsgLoading:	db	" ",0
MsgDot:		db	".",0
MsgNoInt13hExt:	db	CR,LF,"NoInt13hExt",0 ;"INT 13h Extensions is not supported by system BIOS",CR,LF,0
MsgExtReadErr:	db	CR,LF,"ExtReadErr",0 ;"INT 13h Extended Read Error",CR,LF,0
%if USE_VERIFY_SHORT_READ
MsgShortRead:	db	CR,LF,"ExtReadShort",0 ;"INT 13h Extended Read was short",CR,LF,0
%endif ;USE_VERIFY_SHORT_READ
MsgHang:	db	CR,LF,"System halted",CR,LF,0


%if SAVE_INIT_REGS
EntryRegsStart:
EntryEAX	dd	0
EntryEBX	dd	0
EntryECX	dd	0
EntryEDX	dd	0
EntryESI	dd	0
EntryEDI	dd	0
EntryDS		dw	0
EntryES		dw	0
EntryRegsEnd:
%endif ;%if SAVE_INIT_REGS


		;INT 13h Extensions Device Address Packet
InitDAP:	db	10h				;00h Size of DAP (10h or 18h)
		db	00h				;01h Reserved (0)
%if (USE_PERM_7C00H)
		db	((Init_length + 511) / 512) - 1	;02h Number of blocks to transfer (7Fh max)
%else ;USE_PERM_7C00H
		db	((Init_length + PERMSIZE + 511) / 512) - 1 ;02h Number of blocks to transfer (7Fh max)
%endif ;USE_PERM_7C00H
		db	0				;03h Reserved (0)
		dd	0				;04h Transfer buffer (Seg:Ofs)
		dq	1				;08h Starting LBA
							;10h

							
;------------------------------------------------------------------------------
;Configuration Variables
;  These can be patched with a sector editor before booting.
;------------------------------------------------------------------------------
		times	1B0h-($-$$) db 0
VerboseLevel:	db	VERBOSE_LEVEL		;1B0 see common.ninc
DbgLevel:	db	DBG_LEVEL		;1B1 see common.ninc
DbgComIoBase:	dd	DBG_COM_IO_BASE		;1B2 see common.ninc
Unused1B6	dw	0			;1B6
UefiDiskSig	dd	00000000h		;1B8 Win7 writes UEFI disk signature here?
		;Some EFI BIOSes will write a non-zero number to UefiDiskSig if it is zero on boot.
		;http://www.syslinux.org/wiki/index.php/Comboot/chain.c32
		;$ hexdump -s 440 -n 4 -e '"0x%08x\n"' /dev/sda
		;0x000911e6
		;$ fdisk -l /dev/sda
		;...
		;Disk identifier: 0x000911e6
UefiZero1BC	dw	0000h			;1BC UEFI 0000h


;------------------------------------------------------------------------------
;http://homepage2.nifty.com/cars/misc/chs2lba.html
; > 8GB drive: heads = 16 = 10h, sectors = 63 = 3Fh
; mbrlspci.img may never be larger than 64 KBytes = 128 * (512 byte) sectors = 80h sectors
;
;ChsToLbaEAX (perm-asap.nasm)
;  Returns the LBA for the given CHS.
;  TBD Assumes H0 = 16 and S0 = 63.  Should be from INT 13h FN 48h but we're assuming > 8 GiB.
;  Must only be called from Int13hHandler due to use of [bp - #] to access 
;  Int13hHandler entry register values.
;------------------------------------------------------------------------------
	;org	01BEh
	times	1BEh-($-$$) db 0
PartitionTable1:
%if 0
	;http://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
	; untested
	db 	01h	;1BEh Bitflags field: 1 = not bootable, 0x81 = bootable (or "active")
	db	14h	;1BFh Signature-1 (0x14)
	dw	00h	;1C0h Partition Start LBA (high word of 48 bit value)
	db	7Fh	;1C1h partition type 0x7F = proprietary
	; CHS address of last absolute sector in partition
	db	0EBh	;1C2h Signature-2 (0xeb)
	dw	00h	;1C3h Partition Length (high word of 48 bit value)
	dd	00000001h	;1C6h Partition Start LBA (low dword)
	dd	00000080h	;1CAh Partition Length (low dword)
%elif 0
	;Alt-OS-Development Partition Specification (AODPS)
	; http://web.archive.org/web/20050408024220/http://www.adaos.net/aodps/aodps.html
	; Windows Disk Manager will show a small 64 KiB deletable partition
	db 	00h	;1BEh status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;1BFh head (bits 7-0)
	db	02h	;1C0h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C1h cylinder (bits 7-0)
	db	7Fh	;1C2h partition type 0x7F = proprietary / AODPS
	; CHS address of last absolute sector in partition
	db	02h	;1C3h head (bits 7-0)
	db	03h	;1C4h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C5h cylinder (bits 7-0)
	dd	00000001h	;1C6h LBA of first absolute sector in partition
	dd	00000080h	;1CAh Number of sectors in partition (64 KiB)
%elif 0
	;GPT Protective MBR
	; TBD requires a GPT with a GUID telling Windows Disk Manager to ignore the disk
	; untested
	; http://thestarman.narod.ru/asm/mbr/GPT.htm#GPTPT
	db 	00h	;1BEh status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;1BFh head (bits 7-0)
	db	02h	;1C0h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C1h cylinder (bits 7-0)
	db	0EEh	;1C2h partition type 0x73 = reserved
	; CHS address of last absolute sector in partition
	db	0FFh	;1C3h head (bits 7-0)
	db	0FFh	;1C4h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	0FFh	;1C5h cylinder (bits 7-0)
	dd	00000001h	;1C6h LBA of first absolute sector in partition
	dd	00000000h	;1CAh Number of sectors in partition
%elif 0
	;Windows 8 Partition Type 73h Reserved with all other fields 0
	; found by observation and experimentation
	; >>> Windows Disk Manager will show the disk grayed out and unconfigurable <<<
	db 	00h	;1BEh status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;1BFh head (bits 7-0)
	db	00h	;1C0h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C1h cylinder (bits 7-0)
	db	73h	;1C2h partition type 0x73 = reserved
	; CHS address of last absolute sector in partition
	db	00h	;1C3h head (bits 7-0)
	db	00h	;1C4h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C5h cylinder (bits 7-0)
	dd	00000000h	;1C6h LBA of first absolute sector in partition
	dd	00000000h	;1CAh Number of sectors in partition
%elif 1
	;Partition is empty (all zeros)
	; Windows Disk Manager shows the disk as unallocated / ready to create partitions
	db 	00h	;1BEh status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;1BFh head (bits 7-0)
	db	00h	;1C0h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C1h cylinder (bits 7-0)
	db	00h	;1C2h partition type
	; CHS address of last absolute sector in partition
	db	00h	;1C3h head (bits 7-0)
	db	00h	;1C4h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;1C5h cylinder (bits 7-0)
	dd	00000000h	;1C6h LBA of first absolute sector in partition
	dd	00000000h	;1CAh Number of sectors in partition
%else
%error PartitionTable1 is undefined!
%endif

;------------------------------------------------------------------------------
	;org	01CEh
	times	1CEh-($-$$) db 0
PartitionTable2:
	;Partition is empty (zeros)
	db 	00h	;+0h status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;+1h head (bits 7-0)
	db	00h	;+2h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+3h cylinder (bits 7-0)
	db	00h	;+4h partition type
	; CHS address of last absolute sector in partition
	db	00h	;+5h head (bits 7-0)
	db	00h	;+6h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+7h cylinder (bits 7-0)
	dd	00000000h	;+8h LBA of first absolute sector in partition
	dd	00000000h	;+Ch Number of sectors in partition

;------------------------------------------------------------------------------
	;org	01DEh
	times	1DEh-($-$$) db 0
PartitionTable3:
	db 	00h	;+0h status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;+1h head (bits 7-0)
	db	00h	;+2h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+3h cylinder (bits 7-0)
	db	00h	;+4h partition type
	; CHS address of last absolute sector in partition
	db	00h	;+5h head (bits 7-0)
	db	00h	;+6h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+7h cylinder (bits 7-0)
	dd	00000000h	;+8h LBA of first absolute sector in partition
	dd	00000000h	;+Ch Number of sectors in partition

;------------------------------------------------------------------------------
	;org	01EEh
	times	1EEh-($-$$) db 0
PartitionTable4:
	;Partition is empty (zeros)
	db 	00h	;+0h status / physical drive
	; CHS address of first absolute sector in partition
	db	00h	;+1h head (bits 7-0)
	db	00h	;+2h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+3h cylinder (bits 7-0)
	db	00h	;+4h partition type
	; CHS address of last absolute sector in partition
	db	00h	;+5h head (bits 7-0)
	db	00h	;+6h cylinder ((bits 9-8) >> 2) | sector (bits 5-0)
	db	00h	;+7h cylinder (bits 7-0)
	dd	00000000h	;+8h LBA of first absolute sector in partition
	dd	00000000h	;+Ch Number of sectors in partition

;------------------------------------------------------------------------------
BootSignature:
;------------------------------------------------------------------------------
	;org	01FEh
	times	1FEh-($-$$) db 0
	db	055h
	db	0AAh


;------------------------------------------------------------------------------
;Stage1
;Input
;  dl boot drive number (should be 80h)
;  si scrambled
;------------------------------------------------------------------------------
		;org 600h + 200h

;-----------------------------------------------------------------------------
;PR_STR_CS
;-----------------------------------------------------------------------------
%macro PR_STR_CS 0
%if USE_INT_10H
		call	PrStrCS			;Always output to serial COM port
%else ;USE_INT_10H
		call	PrStrCS1		;Always output INT 10h, regardless of USE_INT_10H
		call	PrStrCS			;Always output to serial COM port, USE_INT_10H=0
%endif ;USE_INT_10H
%endmacro ;PR_STR_CS


%if ((BUILD_TYPE == BUILD_TYPE_EXE)) ;DOS .EXE file for testing
..start:
		mov	si, MsgSignOn1
		PR_STR_CS

		mov	si, MsgLoading
		PR_STR_CS

		;COM_INIT
		PR_STR CR,LF,"BUILD_TYPE = 2 (.COM) or 3 (.EXE)",CR,LF

		;obsolete code warning: entry registers may not be set correctly
		mov	dl, 80h
%endif ;%if (BUILD_TYPE)

Vbr:
Stage1:

%if (BUILD_TYPE == BUILD_TYPE_MBR)
		COM_INIT
%else ;%if (BUILD_TYPE)
%endif ;%if (BUILD_TYPE)


		;VMware serial1.txt will _not_ show this dot before Copyright
		; as PrVlDot does not use PrStrCS
		call	PrVlDot


		test	byte [cs:VerboseLevel], VL_SIGN_ON
		jz	.SkipMsgCopyright1
		mov	si, MsgCopyright
		PR_STR_CS
		PR_CRLF
.SkipMsgCopyright1:


	;call	PrChecksum1		;TBD DBG


		DBG_PR_REGS DL_0A, "__LINE__"

DBGLVL_COMINIT equ DL_MAX
;%define DBGLVL_COMINIT DL_MAX
		DBG_PR_STR_CRLF DBGLVL_COMINIT, "__LINE__ COM1 port @ [0:400h], COM2 @ [0:402h], ... COM4 @ [0:406]"
		push	ecx
		;push	esi
		mov	esi, 400h
		mov	ecx, (10h * 1) * 2
		DBG_PR_BUF DBGLVL_COMINIT, "__LINE__"
		;pop	esi
		pop	ecx

%if 0;(USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_DBG_S1)
		push	ax
		push	si
		mov	si, MsgPause
		PR_STR_CS
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE


%if 0
		test	byte [cs:VerboseLevel], VL_STEPS
		jz	.SkipMsgRunning
		mov	byte [cs:VlStepNum], 0
		mov	si, MsgRunning
		PR_STR_CS
.SkipMsgRunning:
%endif
		DBG_PR_REGS DL_0A, "__LINE__"
		
		jmp	AodpsEnd


;-----------------------------------------------------------------------------
;Alt-OS-Development Partition Specification (AODPS)
; http://web.archive.org/web/20050408024220/http://www.adaos.net/aodps/aodps.html
;
;WARNING: We violate AODPS here by assuming 512 byte sectors, and locate the
;         TISP at the fixed offset 508 in this sector (LBA 1).
;-----------------------------------------------------------------------------
		;4 bytes from end of LBA 1
		times	400h-($-$$)-4 db 0
AodpsTisp:	dw	AodpsTis
		;Beginning of LBA 2
		times	400h-($-$$) db 0
AodpsTis:	db	0A0h		;TIS Validation Tag 0
		db	0DFh		;TIS Validation Tag 1
AodpsTisVtn:	db	"http://bitly.com/1Or7xOM",0 ;TIS Volume Type Name (VTN)
		;TIS Named Attibutes List (NAL)
		db	"Bootable=No",0
		db	"Movable=No",0
		db	"Name=mbrlspci",0
		db	"Version=",VERSION_STR," ",__DATE__," ",__TIME__,0
		db	"Visible=No",0
		times	1 db 0		;Reserved for future use
		db	0		;NAL Terminator


		;Non-AODPS Binary Blobs in Tag+Length+Value (TLV) format

AddLbaOfsTag:
		db	"AddLbaOfs="
AddLbaOfsLength:
		db	8
AddLbaOfsValue:
AddLbaOfs:	dq	0;400h		;1B6 DBG PERM(ADD_LBA_OFS)
		;400h LBA sectors for example:
		; 400h sectors / 1 lba_offset (512 bytes / 1 sector) =
		; 524288 bytes / lba_offset =
		; 512 KBytes / lba_offset =
		; 524288 Bytes / lba_offset
		; # dd if=/dev/sdc of=/dev/sdd seek=1 bs=524288
		;little-endian / least significant byte first

InitInt13hRetryLimitTag:
		db	"InitInt13hRetryLimit="
InitInt13hRetryLimitLength:
		db	1		;1 byte
InitInt13hRetryLimitValue:
		db	INT_13H_INIT_RETRY_LIMIT

InitInt13hRetryDelayUsTag:
		db	"InitInt13hRetryDelayMicroseconds="
InitInt13hRetryDelayUsLength:
		db	4		;4 bytes
InitInt13hRetryDelayUsValue:
		dd	INT_13H_INIT_RETRY_DELAY_US

		db	0		;End tag
		db	0		;End length
		db	0		;End value

		align	8
AodpsEnd:

		call	RestoreEntryRegs


%if USE_BIG_REAL_MODE
		;-------------------------------------------------------------
		;Enable CPU to access memory past the x86's 1 MB barrier.
		;  POST Memory Manager Specification Version 1.01,
		;  3.2.4 Accessing Extended Memory, p. 7:
		;  1.  CPU will be in Big real mode
		;  2.  Gate A20 will be disabled (segment wrap turned off)
		;-------------------------------------------------------------
		;call	 mvactivateA20Gate_	;
    		call	StaticBufferESDI	;es:di = Static Buffer
		mov	ax, cs			;ax = cs = GDT segment
		call	UpdateGdtESDI		;ax = GDT segment
		call	AssertGdtESDI		;ax = GDT segment
		call	LoadGdtESDI		;Big Real/Unreal/Flat Mode
%endif ;if USE_BIG_REAL_MODE


		;-------------------------------------------------------------
		;common.ninc
		;Initialize permanent data
		;-------------------------------------------------------------
		mov	PERM(DL_BOOT), dl



		;-------------------------------------------------------------
		;mbrlspci
		;
		;PciScan
		;Info
		;-------------------------------------------------------------


%if 1 ;PciScan

		;-------------------------------------------------------------
		;PciScan
		;References:
		; http://wiki.osdev.org/PCI
		;-------------------------------------------------------------
PCI_CFG_ADDR	equ	0CF8h
PCI_CFG_DATA	equ	0CFCh
		INIT_LINE __LINE__, "PciScan"
		PR_STR_CRLF "PciScan"
		PR_STR_CRLF "Bs Dv Fn Rg Addr     DevVenId Class"
		PR_STR_CRLF "-- -- -- -- -------- -------- --------"

		xor	al, al			;al = 0
		mov	[cs:PciBusNr], al	;
		mov	[cs:PciDevNr], al	;
		mov	[cs:PciFnNr], al	;
		mov	[cs:PciRegNr], al	;Reg 0 = DevVenId

.PciScanNext:
		call	PciCfgRead32

		cmp	eax, -1			;No device = all ones
		je	.PciNextDevice		;


		;Print Addr (ebx) and DevVenId (eax)
		call	PrPciAddrEbxDataEax


		;Class code, Subclass, Prog IF, Rev ID
		mov	byte [cs:PciRegNr], 02h	;Class
		;mov	byte [cs:DbgPciScanShift], 1
		call	PciCfgRead32
		mov	byte [cs:PciRegNr], 00h ;DevVenId
		;mov	byte [cs:DbgPciScanShift], 0

    		call	PrSpace1
		call	PrHexDwordEAX		;Pr Class

		PR_CRLF				;Pr CRLF


%if 0 ;%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_DBG_S1)
		call	KeyPauseVoid
%endif ;USE_KEY_PAUSE


.PciNextDevice:
		cmp	byte [cs:PciDevNr], 31	;Maximum Device Nr?
		je	.PciNextBus

		inc	byte [cs:PciDevNr]
		jmp	.PciScanNext

.PciNextBus:
		cmp	byte [cs:PciBusNr], 255	;Maximum Bus Nr?
		je	.PciScanDone

		mov	byte [cs:PciDevNr], 0
		inc	byte [cs:PciBusNr]
		jmp	.PciScanNext

.PciScanDone:
		;PR_STR_CRLF "} PciScan"
		;PR_CRLF

%endif ;PciScan


%if 1 ;PciFindDevVenId

		;-------------------------------------------------------------
		;Find first specified PCI VendorId & DeviceId
		; starting from [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr}]
		;-------------------------------------------------------------
		xor	al, al			;al = 0
		mov	[cs:PciBusNr], al	;
		mov	[cs:PciDevNr], al	;
		mov	[cs:PciFnNr], al	;
		mov	[cs:PciRegNr], al	;Reg 0 = DevVenId

		;Rosewill RC-301EU two serial port PCIe adapter
		; C158 = OXPCIe952 
		; 1415 = Oxford Semiconductor / PLX Technology
		mov	eax, 0C1581415h

		call	PciFindDevVenId
		jc	.PciFindDevVenIdFail

		;Found
		call	PciCfgRead32

		;Print Addr (ebx) and DevVenId (eax)
		call	PrPciAddrEbxDataEax

		;Class code, Subclass, Prog IF, Rev ID
		mov	byte [cs:PciRegNr], 02h	;Class
		;mov	byte [cs:DbgPciScanShift], 1
		call	PciCfgRead32
		mov	byte [cs:PciRegNr], 00h ;DevVenId
		;mov	byte [cs:DbgPciScanShift], 0

		;Print Class, ... (eax)
    		call	PrSpace1
		call	PrHexDwordEAX

		PR_STR_CRLF " <<<"

		;Print PCI Configuration Registers
		mov	cl, 7
		call	PrPciCfgRegs

;03 00 00 00 80030000 c1581415 DeviceId:VendorId
;03 00 00 01 80030004 00100006
;03 00 00 02 80030008 07000200 Class:Subclass:...
;03 00 00 03 8003000c 00000010
;03 00 00 04 80030010 cfdfc000 BAR0, MEM, 16K
;03 00 00 05 80030014 cfa00000 BAR1, MEM, 2M
;03 00 00 06 80030018 cf800000 BAR2, MEM, 2M

		;BAR0
		mov	byte [cs:PciRegNr], 04h	;BAR0
		;mov	byte [cs:DbgPciScanShift], 1
		call	PciCfgRead32
		mov	byte [cs:PciRegNr], 00h ;DevVenId
		;mov	byte [cs:DbgPciScanShift], 0

		;Print BAR0 (eax)
    		call	PrSpace1
		call	PrHexDwordEAX

		;"Figure 2 shows the OXPCIe952 configuration space,
		; which is allocated for each function and is always 32
		; bits wide."
		; OXPCIe952 Data Sheet, printed page 9, pdf page 15 of 92.
		mov	edi, eax		;edi = BAR0
		test	al, 07h			;0 = 32-bits wide
		jnz	.PciBar0Fail

		and	edi, 0FFFFFFF0h		;Clear Prefetchable, Type, 0

		;Print [BAR0 + 0000h] = Class code and Rev-ID
		mov	eax, [es:edi + 0000h]	;Class code and Rev-ID
    		call	PrSpace1
		call	PrHexDwordEAX

		PR_STR_CRLF " = [BAR0 + 0000h]"
	PR_REGS

		;UART[0] Registers at 0x1000..0x10FF (use this)
		;UART[1] Registers at 0x1200..0x12FF
	;ttyS4 at MMIO 0xcfbfd000 (irq = 15, base_baud = 4000000) is a 16C950/954
	;ttyS5 at MMIO 0xcfbfd200 (irq = 16, base_baud = 4000000) is a 16C950/954

		add	edi, 1000h		;edi = &UART0_Registers
		mov	ebx, edi		;ebx = &UART0_Registers
		call	ComInit
		  ;[cs:DbgComIoBase] = &UART0_Registers for use by COM routines
		PR_STR_CRLF "Hello world!"

		jmp	.PciFindDevVenIdDone

.PciFindDevVenIdFail:
		PR_STR_CRLF "PciFindDevVenIdFail"
		jmp	.PciFindDevVenIdDone

.PciBar0Fail:
		PR_STR_CRLF "PciBar0Fail"
		jmp	.PciFindDevVenIdDone

.PciFindDevVenIdDone:

%endif ;PciFindDevVenId


		;-------------------------------------------------------------
		;BootLba0
		;-------------------------------------------------------------
.BootLba0:
DBG_PR_STR_CRLF DL_MAX, "__LINE__ .BootLba0:"
		xor	eax, eax
		xor	edx, edx
		;edx:eax = Boot LBA 0
.BootLbaEdxEax:
		;Boot LBA edx:eax

		;-------------------------------------------------------------
		;Read LBA edx:eax from PERM(DL_TIER) to 0:7C00h and jump there
		;  PERM(DL_TIER)
		;-------------------------------------------------------------
		xor	ebx, ebx
		xor	ecx, ecx
		xor	esi, esi			;ds = 0
		mov	ds, si				;
		mov	esi, InitDAP			;ds:esi=DAP
		mov	byte [si + DAP_NUM_BLKS_XFER_1B], 1 ;02h Number of blocks to transfer (7Fh max)
		mov	dword [si + DAP_HOST_XFER_BUF_4B], 00007C00h ;04h Transfer buffer (Seg:Ofs)
		mov	dword [si + DAP_START_LBA + 0], eax ;08h Starting LBA (LS4)
		mov	dword [si + DAP_START_LBA + 4], edx ;08h Starting LBA (MS4)
		movzx	edx, byte PERM(DL_BOOT)	;dl = drive number
		mov	eax, INT_13H_EXT_READ		;Extended Read
DBG_PR_STR_CRLF DL_MAX, ">__LINE__ Read DAP_START_LBA from PERM(DL_TIER) to 0:7C00h and jump there"
DBG_PR_REGS DL_MAX, "__LINE__"

DBG_PR_INIT_DAP DL_MAX, ">__LINE__ DAP before int 13h"


%if 0 ;%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_DBG_S1)
		push	ax
		push	si
		mov	si, MsgPause
		PR_STR_CS
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE


DBG_PR_REGS DL_MAX, "__LINE__"
		;call	Int13h				;Uses Int13hHandler installed in interrupt vector
							; instead of PERM(PREV_INT13H) to use vmap table
		int	13h


		mov	esi, InitDAP			;ds:esi=DAP
DBG_PR_REGS DL_MAX, "__LINE__"
DBG_PR_INIT_DAP DL_MAX, ">__LINE__ DAP after int 13h"
		INIT_LINE __LINE__, "int 13h cf = 1"
		jc	.ErrRdLba
%if INT_13H_CF0_AND_AH0
		cmp	ah, 0
		INIT_LINE __LINE__, "int 13h ah != 0"
		jne	.ErrRdLba
%endif ;INT_13H_CF0_AND_AH0
		INIT_LINE __LINE__, "int 13h success"

		lds	si, [si + DAP_HOST_XFER_BUF_4B]
		and	esi, 0000FFFFh			;zero extend to high word
%if 1
DBG_PR_STR_CRLF DL_MAX, "__LINE__ MBR from drive DL:"
DBG_PR_REGS DL_MAX, "__LINE__"
push	ecx
push	es		;Save es = seg Perm
push	ds		;es = ds
pop	es		;
mov	ecx, 512
DBG_PR_BUF DL_MAX, "__LINE__"
pop	es		;Restore es = seg Perm
pop	ecx
%endif

		cmp	word [ds:si + 1FEh], 0AA55h	;Check MBR/VBR signature
		INIT_LINE __LINE__, "MBR/VBR signature != 0AA55"
		jne	.ErrMissingMbrSig


%if SAVE_INIT_REGS
		call	RestoreEntryRegs
%else ;%if SAVE_INIT_REGS
		mov	dl, PERM(DL_BOOT)		;dl = original boot drive number
%endif ;%if SAVE_INIT_REGS

%if 0
		cmp	dl, 0				;Floppy drive A?
		jne	.EntryDlNonZero
		mov	dl, PERM(DL_BOOT)		;dl = original boot drive number
.EntryDlNonZero:
%endif ;%if 0


		jmp	.BootFailUninstall	;Uninstall. . . .


		;-------------------------------------------------------------
		;jmp 0:7C00h
		;-------------------------------------------------------------
.Entry7C00h:

;References
;1. http://en.wikipedia.org/wiki/Master_Boot_Record#MBR_to_VBR_interface
;2. A.4 Hybrid MBR Boot Code Handover Procedure, BIOS Enhanced Disk Drive Specification 4 (EDD-4),
; printed page 73.
; dl = Disk number
; es:di = Pointer to $PnP structure
; eax = 54504721h "!GPT"
; ds:si = Pointer to the hybrid MBR hand over structure
;http://en.wikibooks.org/wiki/X86_Assembly/Bootloaders#Hard_disks
; ES:SI is expected to contain the address in RAM of the partition table, and 
; DL the boot drive number. Breaking such conventions may render a bootloader 
; incompatible with other bootloaders.

DBG_PR_STR_CRLF DL_MAX, "__LINE__ before jmp 0:7C00h"

%if 0 ;DBG DbgLevel, DBG_LEVEL, DL_*, DBG_ENABLED
push	ax
DBG_PR_STR DL_00, "__LINE__ "
mov	al, DL_00
DBG_PR_HEX_BYTE_AL DL_00
DBG_PR_CRLF DL_00

DBG_PR_STR DL_01, "__LINE__ "
mov	al, DL_01
DBG_PR_HEX_BYTE_AL DL_01
DBG_PR_CRLF DL_01

DBG_PR_STR DL_08, "__LINE__ "
mov	al, DL_08
DBG_PR_HEX_BYTE_AL DL_08
DBG_PR_CRLF DL_08

DBG_PR_STR DL_FE, "__LINE__ "
mov	al, DL_FE
DBG_PR_HEX_BYTE_AL DL_FE
DBG_PR_CRLF DL_FE

DBG_PR_STR DL_FF, "__LINE__ "
mov	al, DL_FF
DBG_PR_HEX_BYTE_AL DL_FF
DBG_PR_CRLF DL_FF

;%ifdef DL_ENABLED
DBG_PR_STR DL_ENABLED, "__LINE__ "
mov	al, DL_ENABLED
DBG_PR_HEX_BYTE_AL DL_ENABLED
DBG_PR_CRLF DL_ENABLED
;%endif ;DL_ENABLED

;%ifdef DL_DISABLED
DBG_PR_STR DL_DISABLED, "__LINE__ "
mov	al, DL_DISABLED
DBG_PR_HEX_BYTE_AL DL_DISABLED
DBG_PR_CRLF DL_DISABLED
;%endif ;DL_DISABLED
pop	ax
%endif

DBG_PR_REGS DL_MAX, "__LINE__"
;%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_DBG_S1)
%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_S1)
DBG_PAUSE_07C00h equ DL_05
%if ((DBG_ENABLED) && (USE_common_asap_nasm))
		cmp	byte [cs:DbgLevel], DBG_PAUSE_07C00h
		jb	.SkipPause07C00h
		push	ax
		push	si
		mov	si, MsgPause
		PR_STR_CS
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
.SkipPause07C00h:
%endif ;DBG_ENABLED
%endif ;USE_KEY_PAUSE
		jmp	0:7C00h


		;-------------------------------------------------------------
		;Error Handlers
		;-------------------------------------------------------------
.ErrMsgPrefix:
		DBG_PR_ERR_REGS DL_00, "!i__LINE__ "	;DL_00 always enabled
		DBG_PR_INIT_DAP DL_00, "i__LINE__ ds:si=InitDAP"
		PR_CRLF
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		;push	si
		; mov	si, MsgSpace2Str
		; PR_STR_CS
		;pop	si
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		ret

.ErrEbdaAllocateAX:
		mov	si, MsgErrEbdaAllocateAX
		jmp	.BootFailPrCRLFSpc2StrCSCRLF
.ErrConvMemTooSmall:
		mov	si, MsgErrConvMemTooSmall
		jmp	.BootFailPrCRLFSpc2StrCSCRLF

.ErrRdLba:
		mov	si, MsgErrRdLba
		jmp	.ErrRd
.ErrWrLba:
		mov	si, MsgErrWrLba
		jmp	.ErrWr
.ErrRd:
	;call	PrInitDataStartMsgs	;TBD DBG
		;CR+LF + "  " + "Error reading " + cs:si ASCIIZ string + CR+LF
		call	.ErrMsgPrefix		;CR+LF + "  "
	;call	PrInitDataStartMsgs	;TBD DBG
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		push	si
		mov	si, MsgErrRd		;"Error reading "
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		PR_STR_CS			;
	;call	PrInitDataStartMsgs	;TBD DBG
		pop	si
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		jmp	.BootFailPrStrCSCRLF	;cs:si ASCIIZ string + CR+LF
.ErrWr:
		;CR+LF + "  " + "Error writing " + cs:si ASCIIZ string + CR+LF
		call	.ErrMsgPrefix		;CR+LF + "  "
		push	si
		mov	si, MsgErrWr		;"Error writing "
		PR_STR_CS			;
		pop	si
		jmp	.BootFailPrStrCSCRLF	;cs:si ASCIIZ string + CR+LF

.ErrNotFound:
		call	.ErrMsgPrefix		;CR+LF + "  "
		PR_STR_CS			;Print cs:si
		mov	si, MsgErrNotFound	;" not found"
		jmp	.BootFailPrStrCSCRLF

.InvalidPartitionTable:
		mov	si, MsgErrInvalidPartitionTable	;"Invalid partition table"
.ErrPrCsSiCrLfBootFail:
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		PR_STR_CS			;Pr cs:si
.ErrPrCrLfBootFail:
		PR_CRLF
		jmp	.BootFailUninstall	;Uninstall. . . .

.ErrLoadingVbr:
		mov	si, MsgErrLoadingVbr	;"Error loading VBR"
		jmp	.ErrPrCsSiCrLfBootFail

.ErrMissingMbrSig:
		mov	si, MsgErrMissingMbrSig	;"Missing MBR/VBR signature"
		jmp	.ErrPrCsSiCrLfBootFail


		;-------------------------------------------------------------
		;Error Boot Fail Message
		;Input
		;  cs:si = ASCIIZ string
		;-------------------------------------------------------------
.BootFailPrCRLFSpc2StrCSCRLF:
		call	.ErrMsgPrefix		;CR+LF + "  "
.BootFailPrStrCSCRLF:
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		PR_STR_CS			;cs:si ASCIIZ string + CR+LF
		PR_CRLF				;
	;DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "

.BootFailUninstall:
		INIT_LINE __LINE__, ".BootFailUninstall:"


%if 1 ;Boot active partition

		INIT_LINE __LINE__, "Boot active partition"

		;-------------------------------------------------------------
		;Find and boot the active partition's Volume Boot Record (VBR)
		;-------------------------------------------------------------
.FindActivePartition:
		mov	di, PartitionTable1	;1BEh First partition entry offset
		mov	cl, 4			;cl = number of partition table entries
.CheckActivePartition:
		cmp	byte [cs:di], 80h	;Active/bootable partition?
	DBG_PR_REGS DL_MAX, "__LINE__ .CheckActivePartition:"
		je	.FoundActivePartition	; yes
		cmp	byte [cs:di], 00h	; no: is it 00h?
	DBG_PR_REGS DL_MAX, "__LINE__ .CheckActivePartition:"
		jne	.InvalidPartitionTable	;  no: error
		add	di, 10h			;  yes: next partition table entry
		dec	cl			;any more partition entries left?
		INIT_LINE __LINE__, "Any more active partitions?"
	DBG_PR_REGS DL_MAX, "__LINE__ .CheckActivePartition:"
		jnz	.CheckActivePartition	; yes: continue
		INIT_LINE __LINE__, "No active partition found"
		PR_STR_CRLF "No active partition found"
		jmp	BootFail		;I give up!

.FoundActivePartition:
	DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
		;edx:eax = LBA of first absolute sector of active partition
		mov	eax, dword [cs:di + 8h]
		xor	edx, edx

%if 0 ;BootLbaEdxEax
		INIT_LINE __LINE__, "Boot VBR edx:eax without looking for other active partitions"
		jmp	.BootLbaEdxEax
		;TBD if we run out of space in INIT, use this to skip
		; enforcement of only one active partition.
%else ;BootLbaEdxEax
		;xor	ebx, ebx
		;xor	ecx, ecx
		xor	esi, esi		;ds = 0
		mov	ds, si			;
		mov	esi, InitDAP		;ds:esi=DAP
		mov	byte [si + DAP_NUM_BLKS_XFER_1B], 1 ;02h Number of blocks to transfer (7Fh max)
		mov	dword [si + DAP_HOST_XFER_BUF_4B], 00007C00h ;04h Transfer buffer (Seg:Ofs)
		mov	dword [si + DAP_START_LBA + 0], eax ;08h Starting LBA (LS4)
		mov	dword [si + DAP_START_LBA + 4], 0 ;08h Starting LBA (MS4)
		movzx	edx, byte PERM(DL_BOOT)	;dl = drive number
		mov	eax, INT_13H_EXT_READ	;Extended Read

		;Remaining partition table entries must be 00h
.CheckInactivePartition:
		add	di, 10h			;next partition table entry
		dec	cl			;is this the last entry?
		INIT_LINE __LINE__, "Any more inactive partitions?"
		jz	.BootVbr		; yes: boot the VBR

		cmp	byte [cs:di], 00h	;00h?
		INIT_LINE __LINE__, "Inactive partition"
		je	.CheckInactivePartition	; yes: continue
		INIT_LINE __LINE__, "Non-inactive partition found"
		jmp	.InvalidPartitionTable	; no: error


.BootVbr:
DBG_PR_REGS DL_MAX, "__LINE__ .BootVbr:"
DBG_PR_INIT_DAP DL_MAX, ">__LINE__ DAP before int 13h"

		push	di			;Save active partition offset
%if 0 ;Int13hHandler has been uninstalled, just INT 13h
		call	PrevInt13h		;Previous INT 13h
%else
		;call	Int13h			;System BIOS as Int13hHandler is uninstalled
		int	13h
%endif
		pop	di			;Restore active partition offset

		;mov	esi, InitDAP		;ds:esi=DAP
DBG_PR_REGS DL_MAX, "__LINE__"
DBG_PR_INIT_DAP DL_MAX, ">__LINE__ DAP after int 13h"

		INIT_LINE __LINE__, "int 13h cf = 1"
		;jc	.ErrRdLba
		jc	.ErrLoadingVbr
%if INT_13H_CF0_AND_AH0
		cmp	ah, 0
		INIT_LINE __LINE__, "int 13h ah != 0"
		;jne	.ErrRdLba
		jne	.ErrLoadingVbr
%endif ;INT_13H_CF0_AND_AH0
		INIT_LINE __LINE__, "int 13h success"

		lds	si, [si + DAP_HOST_XFER_BUF_4B]
		and	esi, 0000FFFFh			;zero extend to high word
%if 1
DBG_PR_STR_CRLF DL_MAX, "__LINE__ VBR from drive DL:"
DBG_PR_REGS DL_MAX, "__LINE__"
push	ecx
push	es		;Save es = seg Perm
push	ds		;es = ds
pop	es		;
mov	ecx, 512
DBG_PR_BUF DL_MAX, "__LINE__"
pop	es		;Restore es = seg Perm
pop	ecx
%endif

		cmp	word [ds:si + 1FEh], 0AA55h	;Check MBR/VBR signature
		INIT_LINE __LINE__, "MBR/VBR signature != 0AA55h"
		jne	.ErrMissingMbrSig
		INIT_LINE __LINE__, "MBR/VBR signature = 0AA55h"

		PR_STR_CRLF "Booting active partition"

		;Set MBR to VBR Entry Registers
		; http://en.wikipedia.org/wiki/Master_Boot_Record#MBR_to_VBR_interface
		call	RestoreEntryRegs
		mov	si, di			;ds:si = active partition

	;DBG_PR_ERR_REGS DL_00, "!i__LINE__ " ;TBD DBG Test printing PERM_LINE_NR
		jmp	.Entry7C00h
%endif ;BootLbaEdxEax

%endif ;Boot active partition


		;-------------------------------------------------------------
		;D.2 INT 18h on Boot Failure
		; If an O/S is either not present, or otherwise not able to 
		; load, execute an INT 18h instruction so that control can be 
		; returned to the BIOS.
		;BIOS Boot Specification Version 1.01, Appendix D, printed page 43.
		;-------------------------------------------------------------
BootFail: ;TBD Move BootFail: to just before BootInt18h:, BootWarm:, or BootCold:
%if 0 ;DBG
	mov	byte [cs:DbgLevel], DL_05		;Increase DbgLevel override
	;DBG_PR_STR_CRLF DL_MAX, "__LINE__ DbgLevel = DL_MAX"
	%warning DbgLevel override
%endif ;DBG

BootInt18h:
		INIT_LINE __LINE__, ".BootInt18h:"

		DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
DBG_PR_STR_CRLF DL_MAX, "__LINE__ before INT 18h"

;%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_DBG_S1)
%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_S1)
DBG_PAUSE_INT18h equ DL_05
%if ((DBG_ENABLED) && (USE_common_asap_nasm))
		cmp	byte [cs:DbgLevel], DBG_PAUSE_INT18h
		jb	.SkipPauseInt18h
		push	ax
		push	si
		mov	si, MsgPause
		PR_STR_CS
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
.SkipPauseInt18h:
%endif ;DBG_ENABLED
%endif ;USE_KEY_PAUSE

		;DBG_PR_STR_CRLF DL_MAX, "__LINE__ .BootInt18h: int 18h"
		int	18h
		;BIOS will immediately try booting the next device.

		;We must use int 18h because of the following:
		; 1. https://subversion.local/trac/ticket/284
		; 2. EBDA is no longer used.
		; 3. Conventional memory is now deallocated.
		;
		;WARNING: Do not do INT 18h.
		; 1. Memory is not cleared.
		; 2. EBDA is not deallocated.
		; 3. If another mbrlspci runs, EBDA will be reallocated again.
		;    Add and detect a PNP header in EBDA to prevent reallocation?
		;jmp	BootWarm		;Warm reboot (fall through directly to BootWarm:)
		
		
BootWarm:	;Simulate Ctrl-Alt-Del
		mov	ax, 40h			;[40h:72h] = 1234h
		mov	es, ax			;
		mov	word [es:72h], 1234h	;
		;jmp	BootVector
BootCold:	;Cold boot with memory count
BootVector:
		DBG_PR_ERR_REGS DL_MAX, "!__LINE__ "
DBG_PR_STR_CRLF DL_MAX, "__LINE__ before jmp 0FFFFh:0h"
%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 >= USE_KEY_PAUSE_S1)
		push	ax
		push	si
		mov	si, MsgErrPauseReboot
		PR_STR_CS
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE
		jmp	0FFFFh:0h		;Reboot vector


;-----------------------------------------------------------------------------
;PciCfgRead32
;Input
;  byte [cs:DbgPciScanShift]
;  byte [cs:PciBusNr]
;  byte [cs:PciDevNr]
;  byte [cs:PciFnNr]
;  byte [cs:PciRegNr]
;Output
;  ebx = Addr writen to PCI_CFG_ADDR
;  eax = Data from PCI_CFG_DATA
;Modifies
;  none
;Reference
;  http://wiki.osdev.org/PCI
;-----------------------------------------------------------------------------
PciCfgRead32:	;proc	near
		push	dx

%define DBG_PciScanShift 1 ;0 or 1 (see cs:DbgPciScanShift)

%if DBG_PciScanShift
%macro DBG_PCI_CFG_READ32_SHIFT 1+
	test	byte [cs:DbgPciScanShift], 1
	jz	%%Done
	PR_CRLF
	PR_STR_CRLF %1
	PR_REGS
	call	KeyPauseVoid
%%Done:
%endmacro ;DBG_PCI_CFG_READ32_SHIFT
%endif ;DBG_PciScanShift

		xor	eax, eax
		xor	ebx, ebx

		;Addr

		mov	al, 1			;Enable
		;and	al, 01h			;1 bit
		;shl	ebx, 1			;
		or	bl, al			;

%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "En"
%endif ;DBG_PciScanShift

		mov	al, 0			;Reserved
		;and	al, 7Fh			;7 bits
		shl	ebx, 7			;
		or	bl, al			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Rs"
%endif ;DBG_PciScanShift

		mov	al, [cs:PciBusNr]	;Bus Number
		;and	al, 0FFh		;8 bits
		shl	ebx, 8			;
		or	bl, al			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Bs"
%endif ;DBG_PciScanShift

		mov	al, [cs:PciDevNr]	;Device Number
		;and	al, 1Fh			;5 bits
		shl	ebx, 5			;
		or	bl, al			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Dv"
%endif ;DBG_PciScanShift

		mov	al, [cs:PciFnNr]	;Function Number
		;and	al, 07h			;3 bits
		shl	ebx, 3			;
		or	bl, al			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Fn"
%endif ;DBG_PciScanShift

		mov	al, [cs:PciRegNr]	;Register Number
		;and	al, 0Fh			;6 bits
		shl	ebx, 6			;
		or	bl, al			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Rg"
%endif ;DBG_PciScanShift

		shl	ebx, 2			;Zeros

		;ebx = Addr
		mov	dx, PCI_CFG_ADDR	;
		mov	eax, ebx		;
		out	dx, eax			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Addr"
%endif ;DBG_PciScanShift

		mov	dx, PCI_CFG_DATA	;eax = Data
		in	eax, dx			;
%if DBG_PciScanShift
		DBG_PCI_CFG_READ32_SHIFT "Data"
%endif ;DBG_PciScanShift

		pop	dx
		ret
;PciCfgRead32	endp


;-----------------------------------------------------------------------------
;PrPciAddrEbxDataEax
;-----------------------------------------------------------------------------
PrPciAddrEbxDataEax: ;proc near

		;Print Addr (ebx) and DevVenId (eax)

		push	eax			;Save DevVenId

		mov	eax, ebx
		shr	eax, 16			;Bus Number
		;and	al, 0FFh		;8 bits
		;call	PrSpace1		;
		call	PrHexByteAL		;

		mov	eax, ebx
		shr	eax, 11			;Device Number
		and	al, 01Fh		;5 bits
		call	PrSpace1		;
		call	PrHexByteAL		;

		mov	eax, ebx
		shr	eax, 8			;Function Number
		and	al, 07h			;3 bits
		call	PrSpace1		;
		call	PrHexByteAL		;

		mov	eax, ebx
		shr	eax, 2			;Register Number
		and	al, 03Fh		;6 bits
		call	PrSpace1		;
		call	PrHexByteAL		;

		mov	eax, ebx
		call	PrSpace1		;
		call	PrHexDwordEAX		;Pr Addr

		pop	eax			;Restore DevVenId

    		call	PrSpace1
		call	PrHexDwordEAX		;Pr DevVenId

		ret

;PrPciAddrEbxDataEax endp


;-----------------------------------------------------------------------------
;PrPciCfgRegs
;  Print the PCI Configration Registers
;  starting from [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr}]
;  for cl PciRegNrs.
;Input
;  [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr}]
;  cl = PciRegNrs
;Output
;  none
;Modifies
;  [cs:PciRegNr+=cl]
;-----------------------------------------------------------------------------
PrPciCfgRegs:	;proc	near
		push	eax
		push	ebx
		push	ecx

.PrNextReg:
		;mov	byte [cs:DbgPciScanShift], 1
		call	PciCfgRead32
		;mov	byte [cs:DbgPciScanShift], 0

		call	PrPciAddrEbxDataEax
		PR_CRLF

		dec	cl
		jz	.PrDone

		cmp	byte [cs:PciRegNr], 7Fh
		je	.PrDone

		inc	byte [cs:PciRegNr]
		jmp	.PrNextReg

.PrDone:
		pop	ecx
		pop	ebx
		pop	eax
		ret

;PrPciCfgRegs	endp


;-----------------------------------------------------------------------------
;PciFindDevVenId
;  Find first specified PCI DeviceId:VendorId
;  starting from [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr}]
;Input
;  [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr}]
;  eax = DeviceId:VendorId
;Output
;  cf = 0: found 
;    [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr=0}]
;  cf = 1: no found
;    [cs:{PciBusNr,PciDevNr,PciFnNr,PciRegNr=0}] at maximum
;Modifies
;  none
;-----------------------------------------------------------------------------
PciFindDevVenId: ;proc	near
		push	eax
		push	ebx
		push	edx

		mov	edx, eax		;edx = DeviceId:VendorId

.PciFindNext:
		call	PciCfgRead32

		cmp	eax, edx		;Found?
		je	.PciFoundDevice		;

.PciNextDevice:
		cmp	byte [cs:PciDevNr], 31	;Maximum Device Nr?
		je	.PciNextBus

		inc	byte [cs:PciDevNr]
		jmp	.PciFindNext

.PciNextBus:
		cmp	byte [cs:PciBusNr], 255	;Maximum Bus Nr?
		je	.PciNotFound

		mov	byte [cs:PciDevNr], 0
		inc	byte [cs:PciBusNr]
		jmp	.PciFindNext

.PciFoundDevice:
		clc
.PciFindDone:
		pop	edx
		pop	ebx
		pop	eax
		ret

.PciNotFound:
		stc
		jmp	.PciFindDone

;PciFindDevVenId endp


;-----------------------------------------------------------------------------
;shrEDXEAXbyCL
;Input
;  edx:eax = value to shift right
;  cl = number of bits to shift right
;Reference
;  http://www.masmforum.com/board/index.php?PHPSESSID=786dd40408172108b65a5a36b09c88c0&topic=11634.msg87644#msg87644
;-----------------------------------------------------------------------------
;SHR_EDXEAX_BY_CL:
;		shrd	eax, edx, cl		;shr edx:eax by cl [0..31]
;		shr	edx, cl
;		ret


;-----------------------------------------------------------------------------
;BitPositionEAXtoECX
;  Returns the single set (1) bit position in EAX to ECX.  If there are no bits
;  set in EAX or there are more than one bit set in EAX, ECX will be 0.
;
;  80386 unsigned division is limited to 32 bits.
;  We need to operate with 64-bit LBAs; however, the divisors are always 
;  powers of 2: 512, 1024, 2048, 4096, ....
;  We shift right to divide (or shift left to multiply) by
;  the bit position set to 1 in the divisor.
;Input
;  eax
;Output
;  ecx = [0..31] the single bit position in EAX which is set to 1, 0 otherwise.
;  zf = 0: cl is non-zero
;  zf = 1: cl is 0
;Modifies
;  none
;-----------------------------------------------------------------------------
%define DBG_BitPositionEAXtoECX 0 ;0 or 1
BitPositionEAXtoECX:
		push	eax
		
		;Find the bit position which is set 1: 9=512, 10=1024, 11=2048, 12=4096, ...
		bsf	ecx, eax
%if DBG_BitPositionEAXtoECX
DBG_PR_STR_CRLF DL_MAX, "__LINE__ BitPositionEAXtoECX:"
DBG_PR_REGS DL_MAX, "__LINE__"
%endif
		jz	.NoBitsSet
		shr	eax, cl
		cmp	eax, 1
%if DBG_BitPositionEAXtoECX
DBG_PR_REGS DL_MAX, "__LINE__"
%endif
		je	.ReturnECX
.NoBitsSet:
		xor	ecx, ecx
.ReturnECX:
		or	ecx, ecx
		pop	eax
		ret
;BitPositionEAXtoECX endp


%if USE_BIG_REAL_MODE

;-----------------------------------------------------------------------------
;StaticBufferESDI
;  es:edi = cs:0
;-----------------------------------------------------------------------------
StaticBufferESDI: ;proc	near
		mov	di, cs
		mov	es, di
		mov	edi, StaticBuffer
		ret

StaticBuffer:
		times	(gdtinfo_end - gdt) db 0

;StaticBufferESDI endp


;-----------------------------------------------------------------------------
;UpdateGdtESDI
;  Update GDT segment in Static Buffer.
;Input
;  ax = GDT segment (destination ROM code segment before write-protect)
;  es:di = Static buffer
;Output
;  none
;Modifies
;  Static Buffer
;  No registers are modified.
;Notes
;  SuperMicro X7DBE InitEntry EBX=00000900, CS=CB00 Run-time address; however,
;  CmnPnpBcvEntry and Int13hHandler are both called with CS=CB00!
;  UpdateGdt must copy cs:gdtinfo to Static Buffer,
;  update GDT segment, then LGDT.
;-----------------------------------------------------------------------------
UpdateGdtESDI:	;proc	near
;DBG_UPDATE_GDT equ 1 ;comment out to disable


		;http://ringzero.free.fr/os/protected%20mode/Pm/PM1.ASM
		;push	eax
		push	ebx
		pushf				;save interrupt flag
		cli				;disable interrupts

		movzx	ebx, ax			;ebx = GDT segment
		shl	ebx, 4                  ; paragraph to byte adjust

		lea	ebx, [cs:gdt + ebx]	;ebx = (gdt_segment << 4) + gdt_offset
%ifdef DBG_UPDATE_GDT
DBG_PR_STR_CRLF DL_MAX, "__LINE__ UpdateGdtESDI: cs:gdt..gdtinfo_end (read-only):"
push	ecx
push	esi
push	es
mov	si, cs
mov	es, si
mov	esi, gdt
mov	ecx, gdtinfo_end - gdt
DBG_PR_BUF DL_MAX, "__LINE__"
pop	es
pop	esi
pop	ecx
%endif ;ifdef DBG_UPDATE_GDT
		mov	word [es:di + 0], gdt_end - gdt - 1
		mov	dword [es:di + 2], ebx
%ifdef DBG_UPDATE_GDT
DBG_PR_STR_CRLF DL_MAX, "__LINE__ UpdateGdtESDI: [es:di + 0..6]:"
DBG_PR_REGS DL_MAX, "__LINE__"
push	ecx
push	esi
push	es
lea	esi, [es:di]
mov	ecx, 2 + 4
DBG_PR_BUF DL_MAX, "__LINE__"
pop	es
pop	esi
pop	ecx
%endif ;ifdef DBG_UPDATE_GDT

		popf				;restore interrupt flag
		pop	ebx
		;pop	eax


.ContinueProtectedMode:

		ret
;UpdateGdtESDI	endp


;-----------------------------------------------------------------------------
;AssertGdtESDI
;  Assert GDT segment in Static Buffer.
;Input
;  ax = GDT segment (usually CS).
;  es:di = Static buffer
;Output
;  none
;Modifies
;  flags
;Notes
;  SuperMicro X7DBE InitEntry EBX=00000900, CS=CB00 Run-time address; however,
;  CmnPnpBcvEntry and Int13hHandler are both called with CS=CB00!
;  UpdateGdt must copy cs:gdtinfo to Static Buffer,
;  update GDT segment, then LGDT.
;-----------------------------------------------------------------------------
AssertGdtESDI:	;proc	near
;DBG_ASSERT_GDT equ 1 ;comment out to disable


		;http://ringzero.free.fr/os/protected%20mode/Pm/PM1.ASM
		;push	eax
		push	ebx
		pushf				;save interrupt flag
		cli				;disable interrupts

%ifdef DBG_ASSERT_GDT
DL_AssertGdtESDI equ DL_MAX
DBG_PR_STR_CRLF DL_AssertGdtESDI, "__LINE__ AssertGdtESDI: [es:di + 0..6]:"
DBG_PR_REGS DL_AssertGdtESDI, "__LINE__"
push	ecx
push	esi
push	es
lea	esi, [es:di]
mov	ecx, 2 + 4
DBG_PR_BUF DL_AssertGdtESDI, "__LINE__"
pop	es
pop	esi
pop	ecx
%endif ;ifdef DBG_ASSERT_GDT

		movzx	ebx, ax			;ebx = GDT segment
		shl	ebx, 4                  ; paragraph to byte adjust

		mov	ecx, dword [es:di + 2]
		;sub	ecx, cs:gdt
		sub	ecx, gdt
		cmp	ecx, ebx
		jz	.Done

%ifdef DBG_ASSERT_GDT
DBG_PR_STR_CRLF DL_0A, "__LINE__ AssertGdtESDI: (ecx = [es:di + 2]) != (ax << 4): gdt segment does not match expected (ax)"
DBG_PR_REGS DL_0A, "__LINE__"

DBG_PR_STR DL_0A, "__LINE__ AssertGdtESDI: system halted "

DL_ASSERT_GDT_SPINNER equ DL_0A
%ifdef DBG_ASSERT_GDT
%if ((DBG_ENABLED) && (USE_common_asap_nasm))
		cmp	byte [cs:DbgLevel], DL_ASSERT_GDT_SPINNER
		jb	@F
		mov	al, '*'
		call	PrCharAL
		xor	ecx, ecx
@@:
%endif ;DBG_ENABLED
%endif ;ifdef DBG_ASSERT_GDT
.WaitTop:
%ifdef DBG_ASSERT_GDT
%if ((DBG_ENABLED) && (USE_common_asap_nasm))
		cmp	byte [cs:DbgLevel], DL_ASSERT_GDT_SPINNER
		jb	@F
		call	PrSpinner
@@:
%endif ;DBG_ENABLED
%endif ;ifdef DBG_ASSERT_GDT
		jmp	.WaitTop

%endif ;ifdef DBG_ASSERT_GDT

.Done:
		popf				;restore interrupt flag
		pop	ebx
		;pop	eax


		ret
;AssertGdtESDI	endp


;-----------------------------------------------------------------------------
;LoadGdtESDI
;  Enable flat mode.
;  TBD: Enable A20?
;  Big Real (Unreal) Mode is used to access memory past the x86's 1 MB barrier.
;  The segment register must be 0 to access memory past the x86's 1 MB barrier
;  after this call.
;Input
;  es:di = Static buffer
;Output
;  none
;Modifies
;  Static Buffer
;  No registers are modified, however, ds, es, gs, fs segment registers are
;  now selectors.  Set them to 0 and their offset will be 4 GB flat addresses.
;  flags
;-----------------------------------------------------------------------------
LoadGdtESDI:	;proc	near
;DBG_LOAD_GDT equ 1 ;comment out to disable


%if 0
		;C:\Vanir_Option_ROM-r571-original\bios\bios\biospost.asm/EnableFlat_
		push	ax
		;cli ;TBD This never gets undone if InRealMode
		smsw	ax			;Are we in real or protected mode?
		test	al, 1			;
		pop	ax
		jnz	.InProtectedMode
		jmp	.InRealMode
.InProtectedMode:
		;sti
		jmp	.ContinueProtectedMode
.InRealMode:
%endif ;if 0


		;http://wiki.osdev.org/Unreal_Mode
		pushf				;save interrupt flag
		cli				;disable interrupts
		push	eax
		push	ebx
		push	ds
		push	es
		push	gs
		push	fs

		;xor	eax, eax		;add code segment to gdt offset
		;mov	ax, cs			;
		;shl	eax, 4                  ; paragraph to byte adjust
;DBG_PR_STR_CRLF DL_MAX, "__LINE__ add	dword ptr cs:gdtinfo[2], eax ;TBD CS READ-ONLY AT THIS POINT?!!!"
		;add	dword ptr cs:gdtinfo[2], eax ;TBD CS READ-ONLY AT THIS POINT?!!!
;DBG_PR_STR_CRLF DL_MAX, "__LINE__ add	dword ptr cs:gdtinfo[2], eax ;finished"
%ifdef DBG_LOAD_GDT
DBG_PR_STR_CRLF DL_MAX, "__LINE__ LoadGdtESDI: 'lgdt fword ptr es:[edi]' before"
%endif ;ifdef DBG_LOAD_GDT
		lgdt	[es:edi]
%ifdef DBG_LOAD_GDT
DBG_PR_STR_CRLF DL_MAX, "__LINE__ LoadGdtESDI: 'lgdt fword ptr es:[edi]' after"
%endif ;ifdef DBG_LOAD_GDT

		mov	eax, cr0		;enter protected mode
		or	al, 1			; set pmode bit
		mov	cr0, eax		;

		mov	bx, 08h			;select descriptor 1
		mov	ds, bx 			; 08 = 1000b
		mov	es, bx 			;
		mov	fs, bx 			;
		mov	gs, bx 			;

		and	al, ~1			;back to real mode
		mov	cr0, eax		;

		pop	fs
		pop	gs
		pop	es
		pop	ds
		pop	ebx
		pop	eax
		popf				;restore interrupt flag


.ContinueProtectedMode:

		ret
;LoadGdtESDI	endp

%endif ;%if USE_BIG_REAL_MODE


;-----------------------------------------------------------------------------
;RestoreEntryRegs
;-----------------------------------------------------------------------------
RestoreEntryRegs: ;proc	near

%if SAVE_INIT_REGS

%if 1 ;%ifdef DBG_DumpEntryRegs
DBG_PR_STR_CRLF DL_MAX, "__LINE__ RestoreEntryRegs:"
push	ecx
push	esi
push	es		;Save es = seg Perm
mov	si, cs
mov	es, si
mov	esi, EntryEAX
mov	ecx, EntryRegsEnd - EntryRegsStart
DBG_PR_BUF DL_MAX, "__LINE__ cs:EntryREGS"
pop	es		;Restore es = seg Perm
pop	esi
pop	ecx
%endif ;%ifdef DBG_DumpEntryRegs

		mov	ax, [cs:EntryES]
		mov	es, ax
		mov	ax, [cs:EntryDS]
		mov	ds, ax
		mov	edi, [cs:EntryEDI]
		mov	esi, [cs:EntryESI]
		mov	edx, [cs:EntryEDX]
		mov	ecx, [cs:EntryECX]
		mov	ebx, [cs:EntryEBX]
		mov	eax, [cs:EntryEAX]
		DBG_PR_REGS DL_MAX, "__LINE__"

		DBG_PR_STR_CRLF DL_MAX, "__LINE__ es:di=$PnP structure"
		mov	esi, edi
		mov	ecx, 20h
		DBG_PR_BUF DL_MAX, "__LINE__"

		mov	esi, [cs:EntryESI]	;Restore esi

		DBG_PR_STR_CRLF DL_MAX, "__LINE__ ds:si=MBR hand over structure"
		push	es
		mov	cx, ds			;es = ds
		mov	es, cx			;
		mov	ecx, 20h
		DBG_PR_BUF DL_MAX, "__LINE__"
		pop	es

		mov	ecx, [cs:EntryECX]	;Restore ecx

%else ;%if SAVE_INIT_REGS
%endif ;%if SAVE_INIT_REGS

		ret
;RestoreEntryRegs endp


;-----------------------------------------------------------------------------
;memmove
;  Copies cx bytes from ds:esi to es:edi.
;  Source and destination may overlap and will be copied in the correct 
;  direction.
;Inputs
;  ecx = number of bytes to copy
;  ds:esi = pointer to source memory
;  es:edi = pointer to destination memory
;Outputs
;  none
;Modifies
;  flags
;Notes
;  To handle the overlap case where destination is higher in memory than 
;  source, add a check and then start copying from high address down to
;  low address (decrementing esi and edi from the end to the start).
;-----------------------------------------------------------------------------
		;public	memmove
memmove:	;proc	near
		push	eax
		push	ebx
		push	ecx
		push	esi
		push	edi

		mov	ax, ds
		mov	bx, es
		cmp	ax, bx
		ja	.SrcIsHigher
		cmp	esi, edi
		ja	.SrcIsHigher
		;jmp	.DstIsHigher

.DstIsHigher:
		add	esi, ecx	;copy from the end
		dec	esi		;
		add	edi, ecx	; to the beginning
		dec	edi		;
.DstIsHigherTop:
     	  	mov	al, [ds:esi]
     	  	mov	[es:edi], al
     	  	dec	esi
     	  	dec	edi
     	  	loop	.DstIsHigherTop
     	  	jmp	.Done

.SrcIsHigher:
     	  	mov	al, [ds:esi]	;copy from beginning to end
     	  	mov	[es:edi], al	;
     	  	inc	esi
     	  	inc	edi
     	  	loop	.SrcIsHigher
     	  	;jmp	.Done

.Done:
      	   	pop	edi
      	   	pop	esi
      	   	pop	ecx
      	   	pop	ebx
      	   	pop	eax
      	   	ret
;memmove	endp


;-----------------------------------------------------------------------------
;memset
;  Sets bytes in memory.
;Inputs
;  al = byte to set
;  ecx = number of bytes to set
;  es:edi = pointer to memory
;Outputs
;  none
;Modifies
;  flags
;References
;  http://wiki.osdev.org/AHCI
;    AHCI port memory space initialization
;-----------------------------------------------------------------------------
		;public	memset
memset:		;proc	near
%if 0
		push	ecx
		push	edi

		cld				;df=0: increment edi
		rep	stosb			;store al to es:edi cx times
						; [probably only es:di (not es:edi)]

		pop	edi
		pop	ecx
		ret
%else
		push	ecx
		push	edi

		or	ecx, ecx		;ecx=0?
		jz	.LoopDone		; yes: done

.LoopTop:
		mov	[es:edi], al		;
		inc	edi
		loop	.LoopTop

.LoopDone:
		pop	edi
		pop	ecx
		ret
%endif
;memset		endp


;-----------------------------------------------------------------------------
;memchecksum16
;  Adds bytes in memory.
;Inputs
;  ax = 0
;  ecx = number of bytes to add
;  es:edi = pointer to memory
;Outputs
;  ax = 16 bit checksum
;Modifies
;  flags
;-----------------------------------------------------------------------------
		;public	memchecksum16
memchecksum16:	;proc	near
		push	ecx
		push	edi

		or	ecx, ecx		;ecx=0?
		jz	.LoopDone		; yes: done

.LoopTop:
		add	al, [es:edi]		;ax += [es:edi]
		adc	ah, 0			;
		inc	edi
		loop	.LoopTop

.LoopDone:
		pop	edi
		pop	ecx
		ret
;memchecksum16	endp


;-----------------------------------------------------------------------------
;PrSpace1
;  Print one space.
;Input
;  none
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrSpace1:	;proc	near
		pushf
		push	ax

		mov	al, ' '
		call	PrCharAL

		pop	ax
		popf
		ret
;PrSpace1	endp


;-----------------------------------------------------------------------------
;PrVlStep
;  Backspaces to previous, increments [cs:VlStepNum], then prints it.
;Input
;  [cs:VlStepNum]
;Output
;  [cs:VlStepNum]
;Modifies
;  none
;-----------------------------------------------------------------------------
PrVlStep:	;proc	near
		pushf
		push	ax
		push	si
		test	byte [cs:VerboseLevel], VL_STEPS
		jz	.SkipMsg

%if (VL_STEPS_TYPE == 2)
		;mov	si, MsgBs2Str
		;PR_STR_CS

		inc	byte [cs:VlStepNum]
		mov	al, [cs:VlStepNum]
		call	PrHexByteAL

		mov	si, MsgBs2Str
		PR_STR_CS
%elif (VL_STEPS_TYPE == 4)
		;mov	si, MsgBs4Str
		;PR_STR_CS

		push	eax
		movzx	eax, word [cs:InitLineNumber]
		call	PrHexWordAX		;PASS
		;call	PrHexDwordEAX		;PASS
    		;call	PrDecDwordEAX		;Print eax in decimal
		pop	eax

		mov	si, MsgBs4Str
		PR_STR_CS
%endif ;VL_STEPS_TYPE

;TBD DBG
%if (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_MBR >= USE_KEY_PAUSE_DBG_MBR)
		push	ax
		push	si
		mov	si, MsgPause
		;call	PrStrCS1
		call	KeyPause
		PR_CRLF
		pop	si
		pop	ax
%endif ;USE_KEY_PAUSE

.SkipMsg:
		pop	si
		pop	ax
		popf
		ret
;PrVlStep	endp


;-----------------------------------------------------------------------------
;PrCapacityDec
;  Print capacity (decimal) using the largest non-zero specific unit
;  (modulo 1024) with the appropriate symbol appended using specific units of
;  IEC 60027-2 A.2 and ISO/IEC 80000-13:2008.
;
;Input
;  edx:eax = Total number of user addressable 512 Byte sectors (64-bit LBA)
;
;       63  61|                  51|                  41|                32
;  edx   _ _ _|_:_ _ _ _  _ _ _ _:_|_ _ _  _ _ _ _:_ _ _|_  _ _ _ _:_ _ _ _
;           29|                  19|                   9|
;         ZiB |        EiB         |        PiB         |        TiB
;
;       31|                  21|                  11|                   1|0
;  eax   _|_ _ _:_ _ _ _  _ _ _|_:_ _ _ _  _ _ _ _:_|_ _ _  _ _ _ _:_ _ _|_
;       31|                  21|                  11|                   1|
;      TiB|       GiB          |       MiB          |        KiB         |
;
;Output
;  none
;Modifies
;  none
;Reference
;  http://en.wikipedia.org/wiki/Binary_prefix#Specific_units_of_IEC_60027-2_A.2_and_ISO.2FIEC_80000
;-----------------------------------------------------------------------------
PrCapacityDec:	;proc	near
;DBG_PR_CAPACITY_DEC=1 ;comment out to disable
		push	eax
		push	ecx
		push	edx

.TryZiB:
		bsr	ecx, edx		;Scans edx for first bit set from bit n to 0
%ifdef DBG_PR_CAPACITY_DEC
DBG_PR_STR_CRLF DL_MAX, "__LINE__ PrCapacityDec: bsr ecx, edx ;Scans edx for first bit set from bit n to 0"
DBG_PR_REGS DL_MAX, "__LINE__"
%endif ;DBG_PR_CAPACITY_DEC
		jz	.Hi32isZero		; if all bits are 0, zf = 1 (contrary to Internet documentation)
		cmp	ecx, 29			;Is ZiB zero?
		jb	.TryEiB			; yes: try EiB
.PrZiB:						; no: PrZiB
    		shr	edx, 29			;edx = ZiB
    		mov	eax, edx		;eax = ZiB
    		mov	cl, 'Z'			;Print eax+" ZiB"
    		jmp	.PrEaxUnit		;
.TryEiB:
		cmp	ecx, 19			;Is EiB zero?
		jb	.TryPiB			; yes: try PiB
.PrEiB:						; no: Print EiB
    		shr	edx, 19			;edx = EiB
    		mov	eax, edx		;eax = EiB
    		mov	cl, 'E'			;Print eax+" EiB"
    		jmp	.PrEaxUnit		;
.TryPiB:
		cmp	ecx, 9			;Is PiB zero?
		jb	.TryTiB			; yes: try TiB
.PrPiB:						; no: Print PiB
    		shr	edx, 9			;edx = PiB
    		mov	eax, edx		;eax = PiB
    		mov	cl, 'P'			;Print eax+" PiB"
    		jmp	.PrEaxUnit		;

.Hi32isZero:					;edx = 0
.TryTiB:					;edx = TiB
		shl	edx, 1			;make room for TiB bit 0
		test	eax, 80000000h		;is TiB bit 0 = 0?
		jz	.SkipTiBbit0		; yes: skip
		or	edx, 1			; no: set TiB bit 0 = 1
.SkipTiBbit0:
   		or	edx, edx		;Is TiB zero?
   		jz	.TryGiB			; yes: try GiB
.PrTiB:						; no: Print TiB
    		mov	eax, edx		;eax = TiB
    		mov	cl, 'T'			;Print eax+" TiB"
    		jmp	.PrEaxUnit		;

.TryGiB:
       		and	eax, 7FFFFFFFh		;TiB bit 0 = 0
		bsr	ecx, eax		;Scans eax for first bit set from bit n to 0
%ifdef DBG_PR_CAPACITY_DEC
DBG_PR_STR_CRLF DL_MAX, "__LINE__ PrCapacityDec: bsr ecx, eax ;Scans eax for first bit set from bit n to 0"
DBG_PR_REGS DL_MAX, "__LINE__"
%endif ;DBG_PR_CAPACITY_DEC
		jz	.Lo32isZero		; if all bits are 0, zf = 1

		cmp	ecx, 21                 ;Is GiB zero?
		jb	.TryMiB			; yes: try MiB
.PrGiB:						; no: Print GiB
    		shr	eax, 21			;eax = GiB
    		mov	cl, 'G'			;Print eax+" GiB"
    		jmp	.PrEaxUnit		;
.TryMiB:
		cmp	ecx, 11			;Is MiB zero?
		jb	.TryKiB			; yes: try KiB
.PrMiB:						; no: Print MiB
    		shr	eax, 11			;eax = MiB
    		mov	cl, 'M'			;Print eax+" MiB"
    		jmp	.PrEaxUnit		;
.TryKiB:
		cmp	ecx, 1                  ;Is KiB zero?
		jb	.TryB			; yes: try B
.PrKiB:						; no: Print KiB
    		shr	eax, 1			;eax = KiB
    		mov	cl, 'K'			;Print eax+" KiB"
    		jmp	.PrEaxUnit		;

.Lo32isZero:					;eax = 0
.TryB:						;KiB = 0
.PrB:
		shl	eax, 9			;0 or 512 KiB
    		mov	cl, ' '			;Print eax+" B"
    		;jmp	PrEaxUnit		;

.PrEaxUnit:	;Print dword+' '+((cl != ' ')? (cl+'iB'): 'B')
		;eax = dword
		;cl = '[ZEPTGMK]'
    		;call	PrHexDwordEAX		;Print eax in hexadecimal
    		call	PrDecDwordEAX		;Print eax in decimal
    		mov	al, ' '
    		call	PrCharAL
    		cmp	cl, ' '			;Is cl = ' '?
    		je	.SkipCLi
		mov	al, cl
    		call	PrCharAL
    		mov	al, 'i'
    		call	PrCharAL
.SkipCLi:
    		mov	al, 'B'
    		call	PrCharAL

.Done:
		pop	edx
		pop	ecx
		pop	eax
		ret

;PrCapacityDec	endp


;-----------------------------------------------------------------------------
;PrDecDwordEAX
;  Write EAX as decimal digits without leading zeros.
;Input
;  eax = 32-bit binary number to write
;Output
;  none
;Modifies
;  flags
;Reference
;  see below
;-----------------------------------------------------------------------------
PrDecDwordEAX:	;proc	near

%if 1

;Reference
;  http://codewiki.wikispaces.com/write_decimal.nasm


.digits:
 
;Supplied: EAX = the number to be printed as unsigned
;          EDI = pointer to the output buffer
;Returned: EDI advanced along the output buffer
;Altered:  None, except flags
 
;The algorithm is in two parts:
;
; 1. Loop repeatedly divide the number by ten leaving the remainder on the
;    stack. This remainder is the rightmost digit of each iteration.
;
; 2. Loop popping the digits off the stack and write them to the output.
;
;The number base is pushed on to the stack first as an end marker.
;
;See http://codewiki.wikispaces.com/write_decimal.nasm
;
 
  push edx
  push eax
 
;Set the number base as a stopper on the stack
 
  push dword [cs:.number_base]
  jmp short .split_test
 
;Split the number into its constituent digits
 
.split_loop:
  xor edx, edx
  div dword [cs:.number_base]   ;Split off the digit to the low byte of EDX
  push edx                   ;Save this digit
 
.split_test:
  cmp eax, [cs:.number_base]
  jae .split_loop
 
;Write the digits. The first is in AL, the rest are on the stack
 
.write_loop:
  add al, "0"
  ;mov [edi], al
  ;inc edi
  call PrCharAL
  pop eax
  cmp eax, [cs:.number_base]
  jne .write_loop
 
;Tidy up and exit
 
  pop eax
  pop edx
  ret


.number_base: dd 10


%elif 0


;WARNING: This causes incorrect printing.

;Reference
;  http://forum.nasm.us/index.php?topic=1103.msg4283#msg4283
;  http://forum.nasm.us/index.php?topic=1103.msg4467#msg4467

;---------------------------------
; showeaxd - print a decimal representation of eax to stdout
; for "debug purposes only"... mostly
; expects: number in eax
; returns: nothing useful
;--------------------------------------
.showeaxd:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    sub esp, 21 ;"18446744073709551615" is 20 decimal digits + '\0'
    lea ecx, [esp + 21]  ; another arbitrary number
    mov ebx, 10  ; we want to divide by 10
    xor esi, esi  ; counter
    mov byte [ss:ecx], 0 ; why do I do this? I dunno. [rcpao: NUL terminate string?]
.top:
    dec ecx
    xor edx, edx
    div ebx
    add dl, '0'
    mov [ss:ecx], dl
    inc esi
    or eax, eax
    jnz .top

    ;print ss:ecx for esi bytes
    push es
    push ss
    pop	es
    xchg ecx, esi ;ecx = counter, esi = ptr
    call PrStrES ;print es:esi
    ;call PrCRLF
    ;call PrBuf
    pop	es

    add esp, 21

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret
;---------------------------------

%endif

;PrDecDwordEAX	endp


;-----------------------------------------------------------------------------
;PrErrRegsPrefix
;  MsgSignOn1  [cs:InitLineNumber]
;  Regs
;Input
;  [word cs:InitLineNumber]
;  es = seg Perm
;Output
;  None
;Modifies
;  None
;-----------------------------------------------------------------------------
PrErrRegsPrefix: ;proc	near
		pushf


%if 1
		;\n
		;mbrlspci v0.1.7.5245 [2014-05-09 13:00:19] _
		push	si

		;PR_CRLF
		;mov	al, '!'
		;call	PrCharAL

		mov	si, MsgSignOn1
		PR_STR_CS

		;mov	si, MsgCopyright
		;PR_STR_CS

		mov	si, MsgSpace1Str
		PR_STR_CS
		mov	si, MsgDateTime
		PR_STR_CS

		pop	si
%endif

		;" Error i__LINE__" (where i = init-asap.nasm)
		PR_STR " Error i",0

		push	eax
		movzx	eax, word [cs:InitLineNumber]
		;call	PrHexWordAX		;Print AX in hexadecimal
		;call	PrHexDwordEAX		;Print EAX in hexadecimal
    		call	PrDecDwordEAX		;Print eax in decimal
		pop	eax

		;" p__LINE__\n" (where p = perm-asap.nasm)
		PR_STR " p",0

		push	eax
		push	es			;Save es
		mov	ax, [cs:PermSeg]	;es = seg Perm
		mov	es, ax			;
		movzx	eax, word PERM(LINE_NR)
		pop	es			;Restore es
		;call	PrHexWordAX		;Print AX in hexadecimal
		;call	PrHexDwordEAX		;Print EAX in hexadecimal
    		call	PrDecDwordEAX		;Print eax in decimal
		pop	eax

		PR_CRLF


		;PR_REGS


		popf
		ret
;PrErrRegsPrefix endp


%if 0
;-----------------------------------------------------------------------------
;PrChecksum1
;  DBG
;-----------------------------------------------------------------------------
PrChecksum1:	;proc near
		pushf
		push	ax
		push	edi
		push	es

		PR_STR "PrChecksum1: AodpsEnd.PrChecksum1Begin to AodpsEnd.PrChecksum1End = "

		mov	di, cs			;es:edi = AodpsEnd.PrChecksum1Begin	;
		mov	es, di			;
		mov	edi, AodpsEnd.PrChecksum1Begin	;

		mov	ecx, AodpsEnd.PrChecksum1End - AodpsEnd.PrChecksum1Begin

		xor	ax, ax			;ax = 0

		;Input
		;  ax = 0
		;  ecx = number of bytes to add
		;  es:edi = pointer to memory
		call	memchecksum16
		;Output
		;  ax = 16 bit checksum

		call	PrHexWordAX

		PR_CRLF

		pop	es
		pop	edi
		pop	ax
		popf
		ret
;PrChecksum1	endp
%endif ;%if 0


%if ((USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_MBR = USE_KEY_PAUSE_DISABLED) && (USE_KEY_PAUSE & USE_KEY_PAUSE_MASK_S1 > USE_KEY_PAUSE_DISABLED))

;-----------------------------------------------------------------------------
;KeyGet
;  Check if a key was pressed using Int 16h, AH=01h Keystroke Status.
;  Remove and return the ASCII character code and Scan code if so.
;  This is a non-blocking routine.  It will always immediately return.
;Input
;  None
;Output
;  zf = 1: no key was pressed
;    ax is unmodified
;  zf = 0: a key was pressed
;    al = ASCII character code
;    ah = scan code
;Modifies
;  ax
;  flags
;-----------------------------------------------------------------------------
KeyGet: 	;proc	near
		push	ax
		mov	ah, 01h		;Keystroke Status
		int	16h		;
		pop	ax
		jz	.KeyGetDone$
		pushf			;Save zf=0
		xor	ah, ah		;Keyboard Read
		int	16h		;
		popf			;Restore zf=0
.KeyGetDone$:
		ret
;KeyGet		endp


;-----------------------------------------------------------------------------
;KeyPause
;  * obsolete: Print a prompt to press any key. *
;  Wait forever until a key is pressed.
;  Return the key.
;Input
;  None
;Output
;  zf = 0: a key was pressed
;    al = ASCII character code
;    ah = scan code
;Modifies
;  ax
;  flags
;-----------------------------------------------------------------------------
KeyPause:	;proc	near
		call	KeyGet
		jz	KeyPause
		ret
;KeyPause	endp


;-----------------------------------------------------------------------------
;KeyPauseVoid
;  Wait forever until a key is pressed.
;Input
;  None
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
KeyPauseVoid:	;proc	near
		pushf
		push	ax

.KeyPauseLoop:
		call	KeyGet
		jz	.KeyPauseLoop

		pop	ax
		popf
		ret
;KeyPauseVoid	endp

%endif ;USE_KEY_PAUSE


%if USE_common_asap_nasm
%include "common.nasm"
%endif ;USE_common_asap_nasm


;-----------------------------------------------------------------------------
;PrMsgErrNotFound
;Input
;  None
;Output
;  None
;Modifies
;  None
;-----------------------------------------------------------------------------
PrMsgErrNotFound: ;proc	near
		push	si
		mov	si, MsgErrNotFound
		PR_STR_CS
		pop	si
		PR_CRLF
		ret
;PrMsgErrNotFound endp


;-----------------------------------------------------------------------------
;PrInitDap
;Input
;  None
;Output
;  None
;Modifies
;  None
;-----------------------------------------------------------------------------
PrInitDap:	;proc	near
		pushf
		push	ax
		push	ecx
		push	esi
		push	es		;Save es = seg Perm

		;InitDAP
		xor     esi, esi	;es = 0
		mov     es, si		;
		mov     si, InitDAP	;es(0):si=DAP
		;mov	ecx, 512
		movzx	ecx, byte [es:si + 0]
		;ecx may only be 00h, 10h, or 20h
		;call	PrBuf
		call	PrBufxxdr

		;InitInt13hRetryMax
		PR_STR "InitInt13hRetry{Max="
		mov	al, byte [cs:InitInt13hRetryMax]
		call	PrHexByteAL

		;InitInt13hRetryLimitValue
		PR_STR ",LimitValue="
		mov	al, byte [cs:InitInt13hRetryLimitValue]
		call	PrHexByteAL

		PR_STR "}"

		PR_CRLF

		pop	es		;Restore es = seg Perm
		pop	esi
		pop	ecx
		pop	ax
		popf
		ret
;PrInitDap	endp


;-----------------------------------------------------------------------------
;Section Init Data
;-----------------------------------------------------------------------------

MsgInitDataStart:

MsgCopyright:	db	CR,LF,"Copyright (c) 2015 Roger C. Pao <rcpao1+mbrlspci@gmail.com>",CR,LF,
MsgDateTime:	db	"[",__DATE__," ",__TIME__,"]",0

InitLineNumber:	dw	0		;Use INIT_LINE to update

MsgRunning:	db	"r00",0

VlStepNum:	db	00h

MsgBs6Str:	db	BS
MsgBs5Str:	db	BS
MsgBs4Str:	db	BS
MsgBs3Str:	db	BS
MsgBs2Str:	db	BS
MsgBs1Str:	db	BS,0


;Error Messages
MsgErrEbdaAllocateAX:
		db	"EBDA allocation failed",0
MsgErrConvMemTooSmall:
		db	"Conventional memory allocation failed",0
MsgErrRd:
		db	"Error reading ",0
MsgErrWr:
		db	"Error writing ",0
MsgErrRdLba:
MsgErrWrLba:
		db	"LBA",0

MsgErrPromoteStateFlag:
		db	"Promote state flag encountered",0
MsgErrNotFound:
		db	" not found",0
MsgErrInvalidPartitionTable:
		db	"Invalid partition table",0
MsgErrLoadingVbr:
		db	"Error loading VBR", 0
MsgErrMissingMbrSig:
		db	"Missing MBR/VBR signature", 0
MsgBootingMbr:
		db	"  Booting MBR on drive ",0
MsgErrPauseReboot:
		db	"Press any key to reboot",0

MsgInitDataEnd:

		
%if USE_BIG_REAL_MODE
;http://wiki.osdev.org/Unreal_Mode
;http://www.codeproject.com/Articles/45788/The-Real-Protected-Long-mode-assembly-tutorial-for
;http://ringzero.free.fr/os/protected%20mode/Pm/PM1.ASM
gdt:
nulldesc	dd	0, 0
flatdatadesc	dw	0FFFFh, 0
		db	0, 92h, 0CFh, 0
;flatdatadesc also matches grub-0.97/stage2/asm.S/gdt: /* data segment */
;We do not touch the code segment
gdt_end:
gdtinfo:
		dw	gdt_end - gdt - 1	;last byte in table
		dw	gdt			;gdt offset in code segment
		dw	0			;gdt code segment to be filled in later
gdtinfo_end:
;http://www.codeproject.com/Articles/45788/The-Real-Protected-Long-mode-assembly-tutorial-for
%endif ;%if USE_BIG_REAL_MODE


		align	16
EbdaCodeOfs:	dw	0000h


PermSeg		dw	0	;section Perm segment (seg Perm)
PermInit	dd	0	;Perm:word [Perm:PERM_INIT_OFS]


InitInt13hRetryAX:
		dw	0	;INT 13h AX Function number
InitInt13hRetryMax:
		db	'r'	;Number of INT 13h retries required in Init.
				; INT_13H_INIT_RETRY_LIMIT indicates 
				; retry limit was reached.


PciBusNr	db	0
PciDevNr	db	0
PciFnNr		db	0
PciRegNr	db	0


;PERM_* variables in Init in the absence of Perm.
DL_BOOT		db	0
LINE_NR		dw	0


DbgPciScanShift	db	0	;0 or 1


NasmVerStr	db	__NASM_VER__,0


		;512 bytes sector aligned padding for perm.img/Perm loading
		times	($-$$+512-1)/512*512-($-$$) db 0
;-----------------------------------------------------------------------------
Init_end:
%if (USE_PERM_7C00H)
%else ;USE_PERM_7C00H
Perm_start:
%endif ;USE_PERM_7C00H
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;Stack for DOS .COM
;TBD: Stack grows downward, so label should be _after_ resb?
;-----------------------------------------------------------------------------
;%if ((BUILD_TYPE == 2) || (BUILD_TYPE == 3)) ;DOS .COM or .EXE file for testing
;		;section stack		nobits		follows=Perm	align=16
;		section	stack		stack
;		resb	64
;%endif


;-----------------------------------------------------------------------------
;Section Size Equates
;-----------------------------------------------------------------------------
	section	Init
Init_start	equ	$$
Init_length	equ	$-$$


;-----------------------------------------------------------------------------
;Init + Perm size must not overwrite stack
;-----------------------------------------------------------------------------
%if (USE_PERM_7C00H)

%assign INIT_LENGTH Init_length
%warning Init_length(INIT_LENGTH) must be less than 7400h(29696) = 7C00h - 600h org - 200h stack.
%assign INIT_SPACE_LEFT 7C00h - 600h - 200h - INIT_LENGTH
%warning Init space left = INIT_SPACE_LEFT

%if ((600h + Init_length) >= (7C00h - 200h))
%error OUT OF MEMORY: (600h + Init) >= (7C00h - 512 stack)
%error Stack is at 7C00h growing down toward 600h and will be 
%error overwritten when Init is read in.
%endif

%else ;USE_PERM_7C00H

%if ((600h + Init_length + PERMSIZE) >= (7C00h - 200h))
%error OUT OF MEMORY: (600h + Init + Perm) >= (7C00h - 512 stack)
%error Stack is at 7C00h growing down toward 600h and will be 
%error overwritten if Init + Perm are read together.
%endif

%endif ;USE_PERM_7C00H


;-----------------------------------------------------------------------------
;DOS .EXE
;-----------------------------------------------------------------------------
%if (BUILD_TYPE == 3)
EXE_end
%endif ;%if (BUILD_TYPE)
