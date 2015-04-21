;-----------------------------------------------------------------------------
;common-asap.nasm -- en_bootier code and perm common functions (Zaphod)
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;PrEbda
;  Print a dump of EBDA.
;Input
;  none
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
DBGLVL_PR_EBDA equ DL_00
PrEbda:		;proc	near
		push	eax
		push	ecx
		push	esi
		push	es

		xor	ecx, ecx	;es = 0
		mov	es, cx		;


		DBG_PR_STR DBGLVL_PR_EBDA, " PrEbda EBDA Segment @ [0:40Eh], MemSize @ [0:413h]",CR,LF
		;DBG_PR_REGS DBGLVL_PR_EBDA, "c__LINE__"
		mov	esi, 400h
		mov	ecx, (10h * 1) * 2
		DBG_PR_BUF DBGLVL_PR_EBDA, "c__LINE__"


		movzx	esi, word [es:40Eh] ;esi = EBDA Segment

	   	DBG_PR_STR DBGLVL_PR_EBDA, "PrEbda: [0:40Eh] = "
		mov	ax, si		;ax = EBDA Segment
		DBG_PR_HEX_WORD_AX DBGLVL_PR_EBDA

		;EBDA exists?
		or	ax, ax		;EBDA Segment = 0?
		jz	.DoneNoEbda	; yes: EBDA does not exist
					; no: EBDA exists

	   	DBG_PR_STR DBGLVL_PR_EBDA, " for "

%if 0
		shl	esi, 4		;paragraph to byte adjust
		movzx	ecx, byte [es:esi]	;ecx = EBDA Size in KiB
%else ;if 0
     		;Use real mode Segment:Offset instead of Big Real Mode 0:32BitOffset
     		mov	es, ax
     		xor	esi, esi
     		movzx	ecx, byte [es:si]	;ecx = EBDA Size in KiB
%endif ;if 0

		mov	al, cl		;al = EBDA Size in KiB
		DBG_PR_HEX_BYTE_AL DBGLVL_PR_EBDA
	   	DBG_PR_STR DBGLVL_PR_EBDA, " KiB = "

		shl	ecx, 10		;KiB to byte adjust

		mov	eax, ecx	;eax = EBDA Size in bytes
		DBG_PR_HEX_DWORD_EAX DBGLVL_PR_EBDA
	   	DBG_PR_STR_CRLF DBGLVL_PR_EBDA, " Bytes"

%if 0
		;TBD DBG Print # KiB of system memory (up to 640 KiB).
		int	12h
		;cwde			;eax = sign extend ax
	   	DBG_PR_STR DBGLVL_PR_EBDA, "int 12h = "
		DBG_PR_HEX_WORD_AX DBGLVL_PR_EBDA
	   	DBG_PR_CRLF DBGLVL_PR_EBDA
%endif

		;TBD DBG_PR_BUF DBGLVL_PR_EBDA, "c__LINE__"		;Print es:esi for ecx bytes
.DoneReturn:
		;DBG_PR_REGS DBGLVL_PR_EBDA, "c__LINE__"
	   	pop	es
		pop	esi
		pop	ecx
		pop	eax
		ret

.DoneNoEbda:
	   	DBG_PR_STR_CRLF DBGLVL_PR_EBDA, ".  EBDA does not exist."
       		jmp	.DoneReturn
;PrEbda		endp


;-----------------------------------------------------------------------------
;PrEbdaBuf
;  Print a dump of EBDA.
;Input
;  none
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrEbdaBuf:	;proc	near
		push	eax
		push	ecx
		push	esi
		push	es
		
		xor	ecx, ecx
		mov	es, cx


		DBG_PR_STR_CRLF DBGLVL_PR_EBDA, " PrEbdaBuf EBDA Segment @ [0:40Eh], MemSize @ [0:413h]"
		;DBG_PR_REGS DBGLVL_PR_EBDA, "c__LINE__"
		mov	esi, 400h
		mov	ecx, (10h * 1) * 2
		DBG_PR_BUF DBGLVL_PR_EBDA, "c__LINE__"


		movzx	esi, word [es:40Eh] ;esi = EBDA Segment

	   	DBG_PR_STR DBGLVL_PR_EBDA, "PrEbdaBuf: [0:40Eh] = "
		mov	ax, si		;ax = EBDA Segment
		DBG_PR_HEX_WORD_AX DBGLVL_PR_EBDA

		;EBDA exists?
		or	ax, ax		;EBDA Segment = 0?
		jz	.DoneNoEbda	; yes: EBDA does not exist
					; no: EBDA exists

	   	DBG_PR_STR DBGLVL_PR_EBDA, " for "

%if 0
		shl	esi, 4		;paragraph to byte adjust
		movzx	ecx, byte [es:esi]	;ecx = EBDA Size in KiB
%else ;if 0
     		;Use real mode Segment:Offset instead of Big Real Mode 0:32BitOffset
     		mov	es, ax
     		xor	esi, esi
     		movzx	ecx, byte [es:si]	;ecx = EBDA Size in KiB
%endif ;if 0

		mov	al, cl		;al = EBDA Size in KiB
		DBG_PR_HEX_BYTE_AL DBGLVL_PR_EBDA
	   	DBG_PR_STR DBGLVL_PR_EBDA, " KiB = "

%if 1
		;TBD DBG Print a minimum of # KiB.
		or	cl, cl
		jnz	.NonZero
		mov	ecx, 2		;2 KiB
.NonZero:
%endif		
		
		shl	ecx, 10		;KiB to byte adjust

		mov	eax, ecx	;eax = EBDA Size in bytes
		DBG_PR_HEX_DWORD_EAX DBGLVL_PR_EBDA
	   	DBG_PR_STR_CRLF DBGLVL_PR_EBDA, " Bytes"


%if 1
		;TBD DBG Print # KiB of system memory (up to 640 KiB).
		int	12h
		;cwde			;eax = sign extend ax
	   	DBG_PR_STR DBGLVL_PR_EBDA, "int 12h = "
		DBG_PR_HEX_WORD_AX DBGLVL_PR_EBDA
	   	DBG_PR_CRLF DBGLVL_PR_EBDA
%endif


		DBG_PR_BUF DBGLVL_PR_EBDA, "c__LINE__"	;Print es:esi for ecx bytes
.DoneReturn:
		;DBG_PR_REGS DBGLVL_PR_EBDA, "c__LINE__"
	   	pop	es
		pop	esi
		pop	ecx
		pop	eax
		ret

.DoneNoEbda:
	   	DBG_PR_STR_CRLF DBGLVL_PR_EBDA, ".  EBDA does not exist."
       		jmp	.DoneReturn
;PrEbdaBuf	endp


;-----------------------------------------------------------------------------
;PrBuf
;  Print buffer using DEBUG output format.
;Z:\develop1\xfer\JWASM_~1>debug
;-d
;0AF5:0100  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0110  00 00 00 00 00 00 00 00-00 00 00 00 34 00 E4 0A   ............4...
;0AF5:0120  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0130  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0140  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0150  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0160  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;0AF5:0170  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;esi------  Hex--------------------------------------------   Printable-------
;  es will always be 0 in flat mode.
;  Only esi will be displayed without the ':'.
;
;Input
;  es:si = pointer to buffer
;  cx = number of bytes to print
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrBuf:		;proc	near
		pushfd
		push	eax
		push	ebx
		push	ecx
		push	edx
		push	esi


		and	esi, 0000FFFFh
		and	ecx, 0000FFFFh
		
		
		;Print es
		PR_STR " PrBuf(ES="
		mov	ax, es
		call	PrHexWordAX
		PR_STR ", ESI="
		mov	eax, esi
		call	PrHexDwordEAX
		PR_STR ", ECX="
		mov	eax, ecx
		call	PrHexDwordEAX
		PR_STR_CRLF ")"


		xor	edx, edx	;edx = 0 byte offset for xxd -r
		
		
.AddressLineTop:
		or	ecx, ecx	;ecx ?= 0
		jz	.Done		; yes: nothing left to print
					; no: continue printing

		;Print esi
		mov	eax, esi	;buffer address
		;mov	eax, edx	;byte offset for xxd -r
		call	PrHexDwordEAX

		mov	al, ' '		;space
		;mov	al, ':'		;colon for xxd -r
		call	PrCharAL	;


		;Print Hex line
		xor	ebx, ebx	;ebx = hex bytes in line printed = 0
					; to rewind esi
					; for printing Printables section

.HexLineTop:
		mov	al, ' '		;space
		cmp	bl, 8		;8th hex byte printed gets a hyphen
		jne	.NoHyphen
		mov	al, '-'		;hyphen
		;mov	al, ' '		;space for xxd -r
.NoHyphen:
		call	PrCharAL	;print ' ' or '-'

		mov	al, [es:si]	;al = hex byte to print
		call	PrHexByteAL

		inc	bl
		inc	esi
		inc	edx
		dec	ecx		;Any more bytes to print?
		jz	.HexLinePad	; no: pad the rest of the hex line
		cmp	bl, 16		;End of line?
		jl	.HexLineTop	; no: print the next hex byte

.HexLinePad:
		sub	esi, ebx	;Rewind es:esi for Printables
		mov	bh, bl		;Save number of hex bytes printed
					; This will be the number of Printables
					; to print.
.HexLinePadTop:
		cmp	bl, 16		;End of line?
		je	.PrintableLine	; yes: print Printables
		call	PrSpace3	; no: print spaces to pad where the
					;     hex byte would have been
		inc	bl		;Continue padding
		jmp	.HexLinePadTop	;


		;Print Printable line
.PrintableLine:
		call	PrSpace3
		xor	bl, bl		;bl = number of Printables printed = 0
.PrintableLineTop:
		cmp	bl, bh		;End of line?
		jge	.DoneCRLF

		mov	al, [es:si]	;al = Printable byte to print
		cmp	al, ' ' 	;is al printable (less than ' ')?
		jl	.NotPrintable	; no: not printable
		cmp	al, 127 	;DEL is not printable
		je	.NotPrintable	;
		jmp	.DoPrCharAL
.NotPrintable:
		mov	al, '.' 	; no: print '.'
.DoPrCharAL:
		call	PrCharAL	;

		inc	bl
		inc	esi
		cmp	bl, 16		;End of line?
		jl	.PrintableLineTop ; no: print the next Printable byte


		call	PrCRLF


		jmp	.AddressLineTop

.DoneCRLF:
		call	PrCRLF

.Done:
		pop	esi
		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		popfd
		ret
;PrBuf		endp


;-----------------------------------------------------------------------------
;PrBufxxdr
;  Print buffer using 'xxd -r' output format.
;$ xxd -g 1 input.bin
;0000000: fa 31 c0 8e d8 8e c0 8e-d0 bc 00 7c 89 e6 bf 00  .1.........|....
;0000010: 06 b9 00 01 f3 a5 ea 1b 06 00 00 6a 02 9d be c6  ...........j....
;0000020: 06 e8 75 00 be f6 06 e8 6f 00 e8 93 00 be 19 07  ..u.....o.......
;0000030: e8 66 00 be 1c 07 e8 60 00 52 b4 41 bb aa 55 cd  .f.....`.R.A..U.
;0000040: 13 5a 72 35 be 2c 07 e8 4f 00 be 8a 07 c7 44 04  .Zr5.,..O.....D.
;0000050: 00 08 b4 42 cd 13 72 29 be 2c 07 e8 3b 00 be 8a  ...B..r).,..;...
;0000060: 07 80 7c 02 27 75 22 be 2c 07 e8 2c 00 be f6 06  ..|.'u".,..,....
;0000070: e8 26 00 e8 4a 00 e9 87 01 be 2f 07 e8 1a 00 eb  .&..J...../.....
;0000080: 10 be 40 07 e8 12 00 eb 08 be 52 07 e8 0a 00 eb  ..@.......R.....
;0000090: 00 be 63 07 e8 02 00 eb fe 50 53 56 2e 8a 04 08  ..c......PSV....
;00000a0: c0 74 0a bb 01 00 b4 0e cd 10 46 eb ef 5e 5b 58  .t........F..^[X
;00000b0: c3 50 b4 01 cd 16 58 74 06 9c 30 e4 cd 16 9d c3  .P....Xt..0.....
;00000c0: e8 ee ff 74 fb c3 65 6e 5f 62 6f 6f 74 69 65 72  ...t..en_bootier
;00000d0: 20 6d 62 72 30 36 30 30 2d 61 73 61 70 2e 6e 61   mbr0600-asap.na
;00000e0: 73 6d 20 56 65 72 73 69 6f 6e 20 30 2e 30 2e 33  sm Version 0.0.3
;00000f0: 38 35 33 0d 0a 00 0d 0a 50 72 65 73 73 20 61 6e  853.....Press an
;0000100: 79 20 6b 65 79 20 74 6f 20 63 6f 6e 74 69 6e 75  y key to continu
;0000110: 65 20 2e 20 2e 20 2e 20 00 0d 0a 00 4c 6f 61 64  e . . . ....Load
;0000120: 69 6e 67 20 73 74 61 67 65 20 31 00 20 2e 00 0d  ing stage 1. ...
;0000130: 0a 4d 73 67 4e 6f 45 78 74 52 65 61 64 0d 0a 00  .MsgNoExtRead...
;esi----  Hex--------------------------------------------  Printable-------
;  es will always be 0 in flat mode.
;  Only esi will be displayed with ':'.
;
;To convert back to binary:
;$ xxd -r input.txt output.bin
;Warning: xdd -r may only allow 7 hex digits for the offset.
;
;Input
;  es:si = pointer to buffer
;  cx = number of bytes to print
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrBufxxdr:	;proc	near
		pushfd
		push	eax
		push	ebx
		push	ecx
		push	edx
		push	esi


		and	esi, 0000FFFFh
		and	ecx, 0000FFFFh
		
		
		;Print es
		PR_STR " PrBufxxdr(ES="
		mov	ax, es
		call	PrHexWordAX
		PR_STR ", ESI="
		mov	eax, esi
		call	PrHexDwordEAX
		PR_STR ", ECX="
		mov	eax, ecx
		call	PrHexDwordEAX
		PR_STR_CRLF ")"


		xor	edx, edx	;edx = 0 byte offset for xxd -r
		
		
.AddressLineTop:
		or	ecx, ecx	;ecx ?= 0
		jz	.Done		; yes: nothing left to print
					; no: continue printing

		;Print esi
		;mov	eax, esi	;buffer address
		mov	eax, edx	;byte offset for xxd -r
		call	PrHexDwordEAX

		;mov	al, ' '		;space
		mov	al, ':'		;colon for xxd -r
		call	PrCharAL	;


		;Print Hex line
		xor	ebx, ebx	;ebx = hex bytes in line printed = 0
					; to rewind esi
					; for printing Printables section

.HexLineTop:
		mov	al, ' '		;space
		cmp	bl, 8		;8th hex byte printed gets a hyphen
		jne	.NoHyphen
		mov	al, '-'		;hyphen
		;mov	al, ' '		;space for xxd -r
.NoHyphen:
		call	PrCharAL	;print ' ' or '-'

		mov	al, [es:si]	;al = hex byte to print
		call	PrHexByteAL

		inc	bl
		inc	esi
		inc	edx
		dec	ecx		;Any more bytes to print?
		jz	.HexLinePad	; no: pad the rest of the hex line
		cmp	bl, 16		;End of line?
		jl	.HexLineTop	; no: print the next hex byte

.HexLinePad:
		sub	esi, ebx	;Rewind es:esi for Printables
		mov	bh, bl		;Save number of hex bytes printed
					; This will be the number of Printables
					; to print.
.HexLinePadTop:
		cmp	bl, 16		;End of line?
		je	.PrintableLine	; yes: print Printables
		call	PrSpace3	; no: print spaces to pad where the
					;     hex byte would have been
		inc	bl		;Continue padding
		jmp	.HexLinePadTop	;


		;Print Printable line
.PrintableLine:
		;call	PrSpace3
		call	PrSpace2
		xor	bl, bl		;bl = number of Printables printed = 0
.PrintableLineTop:
		cmp	bl, bh		;End of line?
		jge	.DoneCRLF

		mov	al, [es:si]	;al = Printable byte to print
		cmp	al, ' ' 	;is al printable (less than ' ')?
		jl	.NotPrintable	; no: not printable
		cmp	al, 127 	;DEL is not printable
		je	.NotPrintable	;
		jmp	.DoPrCharAL
.NotPrintable:
		mov	al, '.' 	; not printable: print '.'
.DoPrCharAL:
		call	PrCharAL	;

		inc	bl
		inc	esi
		cmp	bl, 16		;End of line?
		jl	.PrintableLineTop ; no: print the next Printable byte


		call	PrCRLF


		jmp	.AddressLineTop

.DoneCRLF:
		call	PrCRLF

.Done:
		pop	esi
		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		popfd
		ret
;PrBufxxdr	endp


;%if (DBG_COM_IO_BASE != 0)

;DBG_COM_IO_BASE must never be conditionally compiled else 
;setting MBR offset 0x1B2-3 to F8h 03h will not output to COM1 as there is
;no actual code compiled in the binary image.


;-----------------------------------------------------------------------------
;Initialize serial port.
;
;Input
;  ebx = com I/O base (0 = none, 03F8h = COM1, 02F8h = COM2, ...)
;Output
;  cs:[DbgComIoBase] = ebx
;Modifies
;  flags
;References
;  C:\Vanir_Option_ROM-fails-after-9\bios\Share\share_debug.c
;  C:\Vanir_Option_ROM-fails-after-9\bios\product\Vanir\mv_config.h
;  http://www.national.com/ds/PC/PC16550D.pdf
;  http://www.lammertbies.nl/comm/info/RS-232_flow_control.html
;  http://cs.smith.edu/~thiebaut/ArtOfAssembly/CH13/CH13-3.html
;-----------------------------------------------------------------------------
ComInit: 	;proc	near
		push	eax
		push	edx


		or	ebx, ebx		;ebx = 0?
		jz	.Done			; yes: Done

		mov	dword [cs:DbgComIoBase], ebx

		cmp	ebx, COM4_INT_14H
		jbe	.ComInitInt14h

		cmp	ebx, 0FFFh		;COM*_IO_BASE
		jbe	.ComInitIoBase

		jmp	.ComInitPciBase


.ComInitInt14h:
		;BIOS INT 14h required for VMware Workstation 9 guest?
		mov	al, 11100111b		;9600,n,1,8
		xor	ah, ah			;ah = 0
		mov	dx, bx			;dx = 0 (0=COM1, 1=COM2, 2=COM3, 3=COM4)
		dec	dx			;
		int	14h			;Serial Port Initialization
		;ax = Serial Port Status
		jmp	.Done


.ComInitIoBase:
		or	bx, bx
		jz	.Done

		;Assume DLAB = 0
		mov	dx, bx
		add	dx, UART_IER
		xor	al, al			;Disable UART interrupts
		out	dx, al

		mov	dx, bx
		add	dx, UART_LCR
		mov	al, UART_LCR_DLAB	;DLAB = 1
		out	dx, al

		;Set bit rate - divisor latch low byte
		;/* 0x01 = 115,200 BPS */
		;/* 0x02 = 57,600 BPS */
		;/* 0x03 = 38,400 BPS */
		;/* 0x06 = 19,200 BPS */
		;/* 0x0C = 9,600 BPS */
		;/* 0x18 = 4,800 BPS */
		;/* 0x30 = 2,400 BPS */
		mov	dx, bx
		add	dx, UART_DLL
		mov	al, 01h			;115200 bps
		;mov	al, 0Ch			;9600 bps
		out	dx, al

		mov	dx, bx
		add	dx, UART_DLM
		mov	al, 0			;* bps
		out	dx, al

		mov	dx, bx
		add	dx, UART_LCR
		mov	al, UART_LCR_8N1	;8,N,1
		out	dx, al

		mov	dx, bx
		add	dx, UART_FCR
		mov	al, 0C7h		;UART_FCR_RCVR_TRIGGER_14 + UART_FCR_XMIT_FIFO_RESET + UART_FCR_RCVR_FIFO_RESET + UART_FCR_FIFO_ENABLE
		out	dx, al

		mov	dx, bx
		add	dx, UART_MCR
		mov	al, 0Bh 		;UART_MCR_OUT2 + UART_MCR_RTS + UART_MCR_DTR
		out	dx, al

		;mov	dword [cs:DbgComIoBase], ebx

		jmp	.Done


.ComInitPciBase:
		or	ebx, ebx
		jz	.Done

		;Assume DLAB = 0
		mov	edx, ebx
		add	edx, UART_IER
		xor	al, al			;Disable UART interrupts
		mov	[es:edx], al

		mov	edx, ebx
		add	edx, UART_LCR
		mov	al, UART_LCR_DLAB	;DLAB = 1
		mov	[es:edx], al

		;Set bit rate - divisor latch low byte
		;/* 0x01 = 115,200 BPS */
		;/* 0x02 = 57,600 BPS */
		;/* 0x03 = 38,400 BPS */
		;/* 0x06 = 19,200 BPS */
		;/* 0x0C = 9,600 BPS */
		;/* 0x18 = 4,800 BPS */
		;/* 0x30 = 2,400 BPS */
		mov	edx, ebx
		add	edx, UART_DLL
		mov	al, 01h			;115200 bps
		;mov	al, 0Ch			;9600 bps
		mov	[es:edx], al

		mov	edx, ebx
		add	edx, UART_DLM
		mov	al, 0			;* bps
		mov	[es:edx], al

		mov	edx, ebx
		add	edx, UART_LCR
		mov	al, UART_LCR_8N1	;8,N,1
		mov	[es:edx], al

		mov	edx, ebx
		add	edx, UART_FCR
		mov	al, 0C7h		;UART_FCR_RCVR_TRIGGER_14 + UART_FCR_XMIT_FIFO_RESET + UART_FCR_RCVR_FIFO_RESET + UART_FCR_FIFO_ENABLE
		mov	[es:edx], al

		mov	edx, ebx
		add	edx, UART_MCR
		mov	al, 0Bh 		;UART_MCR_OUT2 + UART_MCR_RTS + UART_MCR_DTR
		mov	[es:edx], al

		;mov	dword [cs:DbgComIoBase], ebx

		jmp	.Done


.Done:
		pop	edx
		pop	eax
		ret
;ComInit	endp


;-----------------------------------------------------------------------------
;ComOutAL
;  Write one byte out the serial COM port (only if CTS is asserted).
;Input
;  common.ninc/USE_CTS_FLOW_CTRL = 0 or 1
;  al = byte to output
;Output
;  none
;Modifies
;  flags
;References
;  C:\Vanir_Option_ROM-fails-after-9\bios\Share\share_debug.c
;  C:\Vanir_Option_ROM-fails-after-9\bios\product\Vanir\mv_config.h
;  http://www.lammertbies.nl/comm/info/RS-232_flow_control.html
;  http://infocenter.arm.com/help/topic/com.arm.doc.ddi0183g/I31531.html
;-----------------------------------------------------------------------------
ComOutAL:	;proc	near
		push	ax
		push	bx
		push	dx

		mov	ebx, dword [cs:DbgComIoBase]
		or	ebx, ebx
		jz	.Done

		cmp	ebx, COM4_INT_14H
		jbe	.ComOutInt14h

		cmp	ebx, 0FFFh		;COM*_IO_BASE
		jbe	.ComOutIoBase

		jmp	.ComOutPciBase


.ComOutInt14h:
		;BIOS INT 14h required for VMware Workstation 9 guest?
		push	ax			;Save al = byte to output

		;Wait for transmitter hold register to be empty
		mov	dx, bx			;dx = 0 (0=COM1, 1=COM2, 2=COM3, 3=COM4)
		dec	dx			;
.ThreNotReadyA:
		mov	ah, 3			;ah = 3 Serial Port Status
		int	14h			;Serial Port I/O
		;ax = Serial Port Status
		test	ax, 2000h		;bit 13: Transmitter holding register empty?
		jz	.ThreNotReadyA
		
%if USE_CTS_FLOW_CTRL
		;CTS flow control
		;Wait for Clear to Send (CTS) before sending
		mov	dx, bx			;dx = 0 (0=COM1, 1=COM2, 2=COM3, 3=COM4)
		dec	dx			;
.CtsNotReadyA:
		mov	ah, 3			;ah = 3 Serial Port Status
		int	14h			;Serial Port I/O
		;ax = Serial Port Status
		test	ax, 0010h		;bit 4: Clear to send (CTS)?
		jz	.CtsNotReadyA
%endif ;if USE_CTS_FLOW_CTRL

		pop	ax			;Restore al = byte to output
		
		;Send al
		mov	dx, bx			;dx = 0 (0=COM1, 1=COM2, 2=COM3, 3=COM4)
		dec	dx			;
		mov	ah, 1			;ah = 1 Transmit a Character to the Serial Port
		int	14h			;Serial Port I/O
		;ax = Serial Port Status
		
		jmp	.Done
		

.ComOutIoBase:
		push	ax			;Save al = byte to output

		;Wait for transmitter hold register to be empty
		mov	dx, bx
		add	dx, UART_LSR
.ThreNotReadyB:
		in	al, dx
		test	al, 20h 		;UART_LSR_THRE
		jz	.ThreNotReadyB

%if USE_CTS_FLOW_CTRL
		;CTS flow control
		;Wait for Clear to Send (CTS) before sending
		mov	dx, bx
		add	dx, UART_MSR
.CtsNotReadyB:
		in	al, dx
		test	al, UART_MSR_CTS
		jz	.CtsNotReadyB
%endif ;if USE_CTS_FLOW_CTRL

%if 0 ;USE_DSR_FLOW_CTRL
		;DSR flow control (very rare)
		;Wait for Data Set Ready  (DSR) before sending
		mov	dx, bx
		add	dx, UART_MSR
.DsrNotReadyB:
		in	al, dx
		test	al, UART_MSR_DSR
		jz	.DsrNotReadyB
%endif ;if USE_DSR_FLOW_CTRL

		pop	ax			;Restore al = byte to output

		;Send al
		pushf
		cli
		mov	dx, bx
		out	dx, al
		popf

		jmp	.Done


.ComOutPciBase:
		push	ax			;Save al = byte to output

		;Wait for transmitter hold register to be empty
		mov	edx, ebx
		add	edx, UART_LSR
.ThreNotReadyC:
		mov	al, [es:edx]
		test	al, 20h 		;UART_LSR_THRE
		jz	.ThreNotReadyB

%if USE_CTS_FLOW_CTRL
		;CTS flow control
		;Wait for Clear to Send (CTS) before sending
		mov	edx, ebx
		add	edx, UART_MSR
.CtsNotReadyC:
		mov	al, [es:edx]
		test	al, UART_MSR_CTS
		jz	.CtsNotReadyB
%endif ;if USE_CTS_FLOW_CTRL

%if 0 ;USE_DSR_FLOW_CTRL
		;DSR flow control (very rare)
		;Wait for Data Set Ready  (DSR) before sending
		mov	edx, ebx
		add	edx, UART_MSR
.DsrNotReadyC:
		mov	al, [es:edx]
		test	al, UART_MSR_DSR
		jz	.DsrNotReadyB
%endif ;if USE_DSR_FLOW_CTRL

		pop	ax			;Restore al = byte to output

		;Send al
		pushf
		cli
		mov	edx, ebx
		mov	[es:edx], al
		popf

		jmp	.Done


.Done:
		pop	dx
		pop	bx
		pop	ax
		ret
;ComOutAL	endp

;%endif ;DBG_ENABLED
;%endif ;%if (DBG_COM_IO_BASE != 0)


%if USE_INT_10H
;-----------------------------------------------------------------------------
;Int10hOutAL
;  Write one byte using Int 10h, AH=0Eh.
;Input
;  al = character to write
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
Int10hOutAL:	;proc	near
		;pusha
		push	ax
		push	bx

		;xor	bx, bx		;bh = page number 0,
					; bl = foreground color
					;      (graphics mode only,
					;      unused if monochrome mode)
		;mov	bx, 1		;grub-0.97/stage1/stage1.S uses 1
		mov	bx, 0007h
		mov	ah, 0Eh
		int	10h

		pop	bx
		pop	ax
		;popa
		ret
;Int10hOutAL	endp
%endif ;if USE_INT_10H


;-----------------------------------------------------------------------------
;_PrCharAL
;  Write one character (verbatim) using
;  Int 10h, AH=0Eh and out the serial COM port.
;Input
;  al = character to write
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
_PrCharAL:	;proc	near
		pushf
		push	bx


%if USE_INT_10H
		call	Int10hOutAL
%endif ;if USE_INT_10H


;%if (DBG_COM_IO_BASE != 0)
		mov	bx, word [cs:DbgComIoBase]
		or	bx, bx
		jz	.NoComIoBase
		call	ComOutAL
.NoComIoBase:
;%endif ;%if (DBG_COM_IO_BASE != 0)


		pop	bx
		popf
		ret
;_PrCharAL	endp


;-----------------------------------------------------------------------------
;PrCharAL
;  Write one character (sanitized) using
;  Int 10h, AH=0Eh and out the serial COM port.
;Input
;  al = character to write
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrCharAL:	;proc	near
		pushf
		push	ax
		push	bx

%if 1
		cmp	al, 13		;al = CR?
		je	.Print		; yes, print it
		cmp	al, 10		;al = LF?
		je	.Print		; yes, print it
		;cmp	al, 9		;al = TAB?
		;je	.Print		; yes, print it
		cmp	al, 8		;al = BS?
		je	.Print		; yes, print it
		cmp	al, 7		;al = BEL?
		je	.Print		; yes, print it
		cmp	al, ' '		;al must be a printable character
		jl	.NotPrintable	;
		cmp	al, 127		;DEL is not printable
		je	.NotPrintable	;
		jmp	.Print              ;Assume everything else is printable
.NotPrintable:
%if 1
		; otherwise print "[hex]"
		push	ax
		mov	al, '['
		call	_PrCharAL
		pop	ax
		call	PrHexByteAL	;WARNING: 1 level recursion
		mov	al, ']'
%else
		mov	al, '.'         ; otherwise print '.'
%endif
.Print:                                 ;
%endif


		call	_PrCharAL


		pop	bx
		pop	ax
		popf
		ret
;PrCharAL	endp


;-----------------------------------------------------------------------------
;PrCRLF
;  Write CRLF.
;Input
;  none
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrCRLF:		;proc	near
		push	ax

		mov	al, 13		;CR
		call	PrCharAL	;

		mov	al, 10		;LF
		call	PrCharAL	;

		pop	ax
		ret
;PrCRLF		endp


;-----------------------------------------------------------------------------
;PrBitAL0
;  Write one bit ('0' or '1').
;Input
;  al = bit 0 to write
;       Most significant bits are ignored.
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrBitAL0:	;proc	near
		push	ax

		and	al, 01h		;Mask off high bits
		add	al, '0'		;Print the digit 0-1
		call	PrCharAL	;Print the low nibble

		pop	ax
		ret
;PrBitAL0	endp


;-----------------------------------------------------------------------------
;HexNibbleAL
;  Convert AL into a printable hexadecimal nibble.
;Input
;  al = Least significant bits of hexadecimal nibble to convert
;       Most significant bits are zeroed
;Output
;  al = '0'..'9' or 'A'..'F'
;Modifies
;  flags
;-----------------------------------------------------------------------------
HexNibbleAL:	;proc	near
		and	al, 0Fh		;Mask off high nibble

		cmp	al, 10		;Is it 0-9?
		jge	.Letter		;

		add	al, '0'		;Return the digit 0-9
		jmp	.Done		;

.Letter:		;Letter
		;add	al, 'A'-10	;Return the letter A-F
		add	al, 'a'-10	;Return the letter a-f
.Done:
		ret
;HexNibbleAL	endp


;-----------------------------------------------------------------------------
;PrHexNibbleAL
;  Write one hexadecimal nibble.
;Input
;  al = least significant bits of hexadecimal nibble to write
;       Most significant bits are ignored and untouched.
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrHexNibbleAL:	;proc	near
		push	ax

		call	HexNibbleAL
		call	PrCharAL	;Print the low nibble

		pop	ax
		ret
;PrHexNibbleAL	endp


;-----------------------------------------------------------------------------
;PrHexByteAL
;  Write one hexadecimal byte.
;Input
;  al = hexadecimal byte to write
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrHexByteAL:	;proc	near
		push	ax

		push	ax
		shr	al, 4		;Print the high nibble
		add	al, '0'		;
		call	PrHexNibbleAL
		pop	ax

		add	al, '0'		;Print the low nibble
		call	PrHexNibbleAL

		pop	ax
		ret
;PrHexByteAL	endp


;-----------------------------------------------------------------------------
;PrHexWordAX
;  Write two hexadecimal bytes.
;Input
;  ax = hexadecimal word to write
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrHexWordAX:	;proc	near
		push	ax
		mov	al, ah		;Print the high byte
		call	PrHexByteAL
		pop	ax

		call	PrHexByteAL	;Print the low byte

		ret
;PrHexWordAX	endp


;-----------------------------------------------------------------------------
;PrHexDwordEAX
;  Write four hexadecimal bytes.
;Input
;  eax = hexadecimal dword to write
;Output
;  none
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrHexDwordEAX:	;proc	near
		push	eax
		shr	eax, 16		;Print the high word
		call	PrHexWordAX
		pop	eax

		call	PrHexWordAX	;Print the low word

		ret
;PrHexDwordEAX	endp


;-----------------------------------------------------------------------------
;PrStrESnZ
;  Write ASCIIZ string for ecx bytes.
;Input
;  ecx = maximum number of bytes to write
;  es:si = ASCIIZ string to write
;Output
;  ecx = maximum number of bytes to write - number of bytes written
;        (0 = NUL not found, printed maximum number of bytes)
;Modifies
;  flags
;-----------------------------------------------------------------------------
PrStrESnZ:	;proc	near
		push	ax
		;push	cx
		push	si

		or	cx, cx		;cx=0?
		jz	.PrDone		; yes: done

.PrCharLoopTop:
		mov	al, [es:si]
		or	al, al		;al=NUL?
		jz	.PrDone		; yes: end of string reached

		call	PrCharAL

		inc	si
		loop	.PrCharLoopTop

.PrDone:
		pop	si
		;pop	cx
		pop	ax
		ret
;PrStrESnZ	endp


;-----------------------------------------------------------------------------
;PrStrES
;  Write ASCIIZ string.
;Input
;  es:si = ASCIIZ string to write
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrStrES:	;proc	near
		pushf
		push	ax
		push	si

.PrCharLoopTop:
		mov	al, [es:si]
		or	al, al		;al=NUL?
		jz	.PrDone		; yes: end of string reached

		call	PrCharAL

		inc	si
		jmp	.PrCharLoopTop

.PrDone:
		pop	si
		pop	ax
		popf
		ret
;PrStrES	endp


;-----------------------------------------------------------------------------
;PrStrCS
;  Write ASCIIZ string.
;  PrStrCS1 procedure is only for MBR use.
;  Stage1 should use PrStrCS instead for serial port debug output.
;Input
;  cs:si = ASCIIZ string to write
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrStrCS: 	;proc	near
		push	es

		push	cs		;es=cs
		pop	es		;
		call	PrStrES

		pop	es
		ret
;PrStrCS	endp


;-----------------------------------------------------------------------------
;PrSpace3
;  Write 3 spaces.
;Input
;  none
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrSpace3:	;proc	near
		push	si
		mov	si, MsgSpace3Str
		call	PrStrCS
		pop	si
		ret
;PrSpace3	endp


;-----------------------------------------------------------------------------
;PrSpace2
;  Write 2 spaces.
;Input
;  none
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PrSpace2:	;proc	near
		push	si
		mov	si, MsgSpace2Str
		call	PrStrCS
		pop	si
		ret
;PrSpace2	endp


MsgSpace5Str:	db	" "
MsgSpace4Str:	db	" "
MsgSpace3Str:	db	" "
MsgSpace2Str:	db	" "
MsgSpace1Str:	db	" ",0


%if 0 ;only used in init-asap.nasm
MsgBs6Str:	db	BS
MsgBs5Str:	db	BS
MsgBs4Str:	db	BS
MsgBs3Str:	db	BS
MsgBs2Str:	db	BS
MsgBs1Str:	db	BS,0
%endif


;-----------------------------------------------------------------------------
;PrRegs
;  Print a dump of all registers.
;  This must be called using "call far PrRegs" to push cs on the stack for 
;  printing.
;Input
;  all registers
;Output
;  none
;Modifies
;  none
;-----------------------------------------------------------------------------
PRREGS_USE_EIP equ 0 ;0=use 16-bit ip, 1=use 32-bit eip
PRREGS_USE_PUSHFD equ 0 ;0=use 16-bit pushf, 1=use 32-bit pushfd
  ;pushfd only pushes 16-bits according to CodeView 4 in Win2k cmd.exe box.
PRREGS_USE_CR1 equ 0 ;0=disable, 1=print reserved cr1
PRREGS_USE_CR4 equ 0 ;0=disable, 1=print cr4
PrRegs:		;proc	far
%if PRREGS_USE_EIP
untested
					;[ebp + 10]
					;[ebp + 8] cs of far call return address
					;[ebp + 4] eip of far call return address
%else ;PRREGS_USE_EIP
					;[ebp + 8]
					;[ebp + 6] cs of far call return address
					;[ebp + 4] ip of far call return address
%endif ;PRREGS_USE_EIP
		push	ebp		;[ebp - 0] ebp
		mov	ebp, esp
		push	eax		;[ebp - 4] eax
		push	edx		;[ebp - 8] edx
		push	esi		;[ebp - 12] esi
		push	es		;[ebp - 14] es
%if PRREGS_USE_PUSHFD
untested
		pushfd			;[ebp - 18] 4 byte (32-bit) flags
%else ;PRREGS_USE_PUSHFD
		pushf			;[ebp - 16] 2 byte (16-bit) flags
%endif ;PRREGS_USE_PUSHFD		


		mov	esi, EaxStr		;eax
		call	PrStrCS			;
		call	PrHexDwordEAX		;

		mov	esi, EbxStr		;ebx
		call	PrStrCS			;
		mov	eax, ebx		;
		call	PrHexDwordEAX		;

		mov	esi, EcxStr		;ecx
		call	PrStrCS			;
		mov	eax, ecx		;
		call	PrHexDwordEAX		;

		mov	esi, EdxStr		;edx
		call	PrStrCS			;
		mov	eax, edx		;
		call	PrHexDwordEAX		;

		call	PrCRLF			;

		mov	esi, EspStr		;esp
		call	PrStrCS			;
		;mov	eax, esp		;
		mov	eax, ebp		;eax = esp before PrRegs was called
%if PRREGS_USE_EIP
		add	eax, 4 + 4 + 2		; + sizeof(ebp) + sizeof(eip) + sizeof(cs)
%else ;PRREGS_USE_EIP
		add	eax, 4 + 2 + 2		; + sizeof(ebp) + sizeof(ip) + sizeof(cs)
%endif ;PRREGS_USE_EIP
		call	PrHexDwordEAX		;

		mov	esi, EbpStr		;ebp
		call	PrStrCS			;
		mov	eax, [ebp - 0]		;eax = ebp on entry
		call	PrHexDwordEAX		;

		mov	esi, EsiStr		;esi
		call	PrStrCS			;
		mov	eax, [ebp - 12]		;eax = esi on entry
		call	PrHexDwordEAX		;

		mov	esi, EdiStr		;edi
		call	PrStrCS			;
		mov	eax, edi		;
		call	PrHexDwordEAX		;

		call	PrCRLF			;

		mov	esi, DsStr		;ds
		call	PrStrCS			;
		mov	ax, ds			;
		call	PrHexWordAX		;

		mov	esi, EsStr		;es
		call	PrStrCS			;
		mov	ax, es			;
		call	PrHexWordAX		;

		mov	esi, FsStr		;fs
		call	PrStrCS			;
		mov	ax, fs			;
		call	PrHexWordAX		;

		mov	esi, GsStr		;gs
		call	PrStrCS			;
		mov	ax, gs			;
		call	PrHexWordAX		;

		mov	esi, SsStr		;ss
		call	PrStrCS			;
		mov	ax, ss			;
		call	PrHexWordAX		;

		mov	esi, CsStr		;cs of PrReg's return address
		call	PrStrCS			;
		;mov	ax, cs			;
%if PRREGS_USE_EIP
		mov	ax, [ebp + 8]		;
%else ;if PRREGS_USE_EIP
		mov	ax, [ebp + 6]		;
%endif ;if PRREGS_USE_EIP		
		call	PrHexWordAX		;

%if PRREGS_USE_EIP
		mov	esi, EipStr		;eip of PrReg's return address
%else ;if PRREGS_USE_EIP
		mov	esi, IpStr		;ip of PrReg's return address
%endif ;if PRREGS_USE_EIP
		call	PrStrCS			;
%if PRREGS_USE_EIP
		mov	eax, [ebp + 6]		;
%else ;if PRREGS_USE_EIP
		mov	eax, [ebp + 4]		;
%endif ;if PRREGS_USE_EIP		
%if PRREGS_USE_EIP
		call	PrHexDwordEAX		;
%else ;if PRREGS_USE_EIP
		call	PrHexWordAX		;
%endif ;if PRREGS_USE_EIP

%if PRREGS_USE_PUSHFD
		mov	esi, EflStr		;efl
		call	PrStrCS			;
		mov	eax, [ebp - 16]		;eax=eflags
		call	PrHexDwordEAX		;
%else ;if PRREGS_USE_PUSHFD
		mov	esi, FlStr		;fl
		call	PrStrCS			;
		mov	ax, [ebp - 16]		;ax=flags
		call	PrHexWordAX		;
%endif ;if PRREGS_USE_PUSHFD		

		call	PrCRLF			;


		;EFLAGS
		mov	edx, eax		;edx=eflags

		mov	esi, CfStr
		call	PrStrCS			;
		;mov	eax, edx		;eax=eflags
		;shr	eax, 0			;al=CF
		;and	al, 01h			;
		call	PrBitAL0		;

		mov	esi, F1Str
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 1			;al=F1
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 2			;al=PF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, F3Str
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 3			;al=F3
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, AfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 4			;al=AF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, F5Str
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 5			;al=F5
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, ZfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 6			;al=ZF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, SfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 7			;al=SF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, TfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 8			;al=TF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, IfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 9			;al=IF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, DfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 10 		;al=DF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, OfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 11 		 ;al=OF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, IoplStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 12 		;al=IOPL
		and	al, 03h 		;2 bits
		call	PrHexNibbleAL		;

		mov	esi, NtStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 14 		;al=NT
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, F15Str
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 15 		;al=F15
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		call	PrCRLF			;


%if PRREGS_USE_PUSHFD
		mov	esi, RfStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 16 		;al=RF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, VmStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 17 		;al=VM
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, AcStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 18 		;al=AC
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, VifStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 19 		;al=VIF
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, VipStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 20 		;al=VIP
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, IdStr
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 21 		;al=ID
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, F22Str
		call	PrStrCS			;
		mov	eax, edx		;eax=eflags
		shr	eax, 22 		;al=F22
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		call	PrCRLF			;
%endif ;if PRREGS_USE_PUSHFD


		;http://en.wikipedia.org/wiki/Control_register
		
		;http://en.wikipedia.org/wiki/Control_register#CR0
		mov	esi, Cr0Str		;cr0
		call	PrStrCS			;
		mov	eax, cr0		;
		call	PrHexDwordEAX		;

		mov	edx, cr0		;edx=cr0

		mov	esi, PeStr
		call	PrStrCS			;
		;mov	eax, edx		;eax=cr0
		;shr	eax, 0			;al=PE
		;and	al, 01h			;
		call	PrBitAL0		;

		mov	esi, MpStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 1			;al=MP
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, EmStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 2			;al=EM
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, TsStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 3			;al=TS
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, EtStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 4			;al=ET
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, NeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 5			;al=NE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, WpStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 16			;al=WP
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, AmStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 18			;al=AM
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, NwStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 29			;al=NW
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, CdStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 30			;al=CD
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PgStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr0
		shr	eax, 31			;al=PG
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		call	PrCRLF			;


%if PRREGS_USE_CR1
		mov	esi, Cr1Str		;cr1
		call	PrStrCS			;
		mov	eax, cr1		;
		call	PrHexDwordEAX		;
%endif ;if PRREGS_USE_CR1

		mov	esi, Cr2Str		;cr2
		call	PrStrCS			;
		mov	eax, cr2		;
		call	PrHexDwordEAX		;

		mov	esi, Cr3Str		;cr3
		call	PrStrCS			;
		mov	eax, cr3		;
		call	PrHexDwordEAX		;

		call	PrCRLF			;


%if PRREGS_USE_CR4
		;http://en.wikipedia.org/wiki/Control_register#CR4

		mov	esi, Cr4Str		;cr4
		call	PrStrCS			;
		mov	eax, cr4		;
		call	PrHexDwordEAX		;

		mov	edx, cr4		;edx=cr4

		mov	esi, VmeStr
		call	PrStrCS			;
		;mov	eax, edx		;eax=cr4
		;shr	eax, 0			;al=VME
		;and	al, 01h			;
		call	PrBitAL0		;

		mov	esi, PviStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 1			;al=PVI
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, TsdStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 2			;al=TSD
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, DeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 3			;al=DE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PseStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 4			;al=PSE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PaeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 5			;al=PAE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, MceStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 6			;al=MCE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PgeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 7			;al=PGE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PceStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 8			;al=PCE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, OsfxsrStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 9			;al=OSFXSR
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, OsxmmexcptStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 10			;al=OSXMMEXCPT
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, VmxeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 13			;al=VMXE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, SmxeStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 14			;al=SMXE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, PcideStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 17			;al=PCIDE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, OsxsaveStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 18			;al=OSXSAVE
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, SmepStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 20			;al=SMEP
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		mov	esi, SmapStr
		call	PrStrCS			;
		mov	eax, edx		;eax=cr4
		shr	eax, 21			;al=SMAP
		;and	 al, 01h		 ;
		call	PrBitAL0		;

		call	PrCRLF			;
%endif ;if PRREGS_USE_CR4


%if 0 ;DBG Dump stack
		;Print the stack
		push	ecx

		push	ss			;es = ss
		pop	es			;

		;ecx = how far down the stack to start printing
%if PRREGS_USE_PUSHFD
		mov	ecx, 18			;[ebp - 18]
%else ;PRREGS_USE_PUSHFD
		mov	ecx, 16			;[ebp - 16]
%endif ;PRREGS_USE_PUSHFD

		mov	esi, ebp		;es:esi = ss:ebp - last_push_on_entry
		sub	esi, ecx		; push es @ [ss:ebp - ecx]

		;Print the caller's return address
%if PRREGS_USE_EIP
		add	ecx, 4 + 4 + 2		; + sizeof(ebp) + sizeof(eip) + sizeof(cs)
%else ;PRREGS_USE_EIP
		add	ecx, 4 + 2 + 2		; + sizeof(ebp) + sizeof(ip) + sizeof(cs)
%endif ;PRREGS_USE_EIP

		;es:esi = pointer to buffer
		;ecx = number of bytes to print
		call	PrBuf
		
		pop	ecx

%if 0 ;comment
;init-asap.nasm
LBA 1 / Stage 1: Hello world
566 EAX=00000000 EBX=0000aa55 ECX=00000001 EDX=00000080
 ESP=00007c00 EBP=87654321 ESI=0000078e EDI=00000ad0
 DS=0000 ES=0000 FS=0000 GS=f000 SS=0000 CS=0000 IP=0876 FL=0206
 CF=0 F1=1 PF=1 F3=0 AF=0 F5=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0 IOPL=0 NT=0 F15=0
 CR0=00000012 PE=0 MP=1 EM=0 TS=0 ET=1 NE=0 WP=0 AM=0 NW=0 CD=0 PG=0
 CR2=00000000 CR3=bef93000
 PrBuf(ES=0000, ESI=00007be8, ECX=00000018)
00007be8  06 02 00 00 8e 07 00 00-80 00 00 00 00 00 00 00   ................
00007bf8  21 43 65 87 76 08 00 00                           !Ce.v...
          flags es    esi         edx         eax
          ebp         ip    cs    cs:ip = PrReg's return address
%endif ;comment
		
%endif ;DBG Dump stack


%if PRREGS_USE_PUSHFD
		popfd
%else ;if PRREGS_USE_PUSHFD
		popf
%endif ;if PRREGS_USE_PUSHFD
		pop	es
		pop	esi
		pop	edx
		pop	eax
		mov	esp, ebp
		pop	ebp
		retf				;will pop cs

EaxStr		db	" EAX=",0
EbxStr		db	" EBX=",0
EcxStr		db	" ECX=",0
EdxStr		db	" EDX=",0
EspStr		db	" ESP=",0
EbpStr		db	" EBP=",0
EsiStr		db	" ESI=",0
EdiStr		db	" EDI=",0
DsStr		db	" DS=",0
EsStr		db	" ES=",0
FsStr		db	" FS=",0
GsStr		db	" GS=",0
SsStr		db	" SS=",0
CsStr		db	" CS=",0
EipStr		db	" EIP=",0
IpStr		db	" IP=",0
EflStr		db	" EFL=",0
FlStr		db	" FL=",0
CfStr		db	" CF=",0		;00 Carry flag
F1Str		db	" F1=",0		;01 Reserved=1
PfStr		db	" PF=",0		;02 Parity flag
F3Str		db	" F3=",0		;03 Reserved=0
AfStr		db	" AF=",0		;04 Adjust flag
F5Str		db	" F5=",0		;05 Reserved=0
ZfStr		db	" ZF=",0		;06 Zero flag
SfStr		db	" SF=",0		;07 Sign flag
TfStr		db	" TF=",0		;08 Trap flag
IfStr		db	" IF=",0		;09 Interrupt enable flag
DfStr		db	" DF=",0		;0A Direction flag
OfStr		db	" OF=",0		;0B Overflow flag
IoplStr 	db	" IOPL=",0		;0C I/O privilege level
NtStr		db	" NT=",0		;0D Nested task flag
F15Str		db	" F15=",0		;0E Reserved=0
RfStr		db	" RF=",0		;0F Resume flag
VmStr		db	" VM=",0		;10 Virtual 8086 mode flag
AcStr		db	" AC=",0		;11 Alignment check
VifStr		db	" VIF=",0		;12 Virtual interrupt flag
VipStr		db	" VIP=",0		;13 Virtual interrupt pending
IdStr		db	" ID=",0		;14 Able to use CPUID instruction
F22Str		db	" F22=",0		;15 Reserved=0
Cr0Str		db	" CR0=",0
Cr1Str		db	" CR1=",0
Cr2Str		db	" CR2=",0
Cr3Str		db	" CR3=",0
Cr4Str		db	" CR4=",0
PeStr		db	" PE=",0		;00 Protected Mode Enable
MpStr		db	" MP=",0		;01 Monitor co-processor
EmStr		db	" EM=",0		;02 Emulation
TsStr		db	" TS=",0		;03 Task switched
EtStr		db	" ET=",0		;04 Extension type
NeStr		db	" NE=",0		;05 Numeric Error
WpStr		db	" WP=",0		;10 Write protect
AmStr		db	" AM=",0		;12 Alignment mask
NwStr		db	" NW=",0		;1D Not-write through
CdStr		db	" CD=",0		;1E Cache disable
PgStr		db	" PG=",0		;1F Paging
VmeStr		db	" VME=",0		;00 Virtual 8086 Mode Extensions
PviStr		db	" PVI=",0		;01 Protected-mode Virtual Interrupts
TsdStr		db	" TSD=",0		;02 Time Stamp Disable
DeStr		db	" DE=",0		;03 Debugging Extensions
PseStr		db	" PSE=",0		;04 Page Size Extension
PaeStr		db	" PAE=",0		;05 Physical Address Extension
MceStr		db	" MCE=",0		;06 Machine Check Exception
PgeStr		db	" PGE=",0		;07 Page Global Enabled
PceStr		db	" PCE=",0		;08 Performance-Monitoring Counter enable
OsfxsrStr	db	" OSFXSR=",0		;09 Operating system support for FXSAVE and FXSTOR instructions
OsxmmexcptStr	db	" OSXMMEXCPT=",0	;10 Operating System Support for Unmasked SIMD Floating-Point Exceptions
VmxeStr		db	" VMXE=",0		;13 Virtual Machine Extensions Enable
SmxeStr		db	" SMXE=",0		;14 Safer Mode Extensions Enable
PcideStr	db	" PCIDE=",0		;17 PCID Enable
OsxsaveStr	db	" OSXSAVE=",0		;18 XSAVE and Processor Extended States Enable
SmepStr		db	" SMEP=",0		;20 Supervisor Mode Execution Protection Enable
SmapStr		db	" SMAP=",0		;21 Supervisor Mode Access Protection Enable

;PrRegs		endp


