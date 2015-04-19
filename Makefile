# Makefile for mbrlspci


NASMFLAGS=-O0


.asm.img:
	jwasm -Fl -Sg -Zi -bin -Fo $@ -c $<

.nasm.img:
	nasm -f bin $(NASMFLAGS) -l $@.lst $< -o $@

#.nasm.com:
#	nasm -f bin $(NASMFLAGS) -l $@.lst $< -o $@

.obj.exe:
	jwlink format dos option map name $@ file $<


all: mbrlspci.img 

#DBG 
init.com: init.nasm common.nasm 
	nasm -f bin $(NASMFLAGS) -l init.lst -g -dBUILD_TYPE=2 init.nasm -o init.com

#DBG 
init.exe: init.nasm common.nasm 
	nasm -f bin $(NASMFLAGS) -l init.lst -g -dBUILD_TYPE=3 init.nasm -o init.exe


#dd mbrlspci.img to known drives
ddmbrlspci.img: mbrlspci.img
	# Obsoleted by build.sh.

mbrlspci.img: init.img
	cat init.img > mbrlspci.img

init.img: init.nasm common.ninc common.nasm 
	nasm -f bin $(NASMFLAGS) -l init.lst init.nasm -o init.img
	#nasm -f elf -g -l init.lst init.nasm -o init.elf
	#objcopy -O binary init.elf init.img

init.nasm: init-asap.nasm 
	gawk -f asap.awk < init-asap.nasm > init.nasm

common.nasm: common-asap.nasm
	gawk -f asap.awk < common-asap.nasm > common.nasm

common.ninc: version.ninc 

version.ninc: do-version.sh 
	bash do-version.sh .


clean:
	rm -f *.o *.obj
	rm -f init.img *.com *.exe 1 *.lst *.map init.nasm common.nasm version.ninc 

spotless: clean
	rm -f mbrlspci.img 
