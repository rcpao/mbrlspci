#!/bin/bash

# This sript is designed to be run from anywhere
# (e.g., ~/Documents/mbrlspci):
#  "ub14-vm" VMware Workstation on bun
#
# VM for testing mbr.img.


# ln -s ~/Documents/mbrlspci/build.sh ~/


FPING="fping"
FPINGOPTS=" -q -u "
RSYNC="rsync"
RSYNCOPTS=" -vvz --progress "
GAWK="gawk"
M4="m4"
NASM="nasm"

# http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
for CMD in $FPING $RSYNC $GAWK $M4 $NASM
do
  command -v $CMD >/dev/null 2>&1 || { echo >&2 "$CMD is not installed.  Aborting."; exit 1; }
done


#cd ~/Documents/mbrlspci/
#svn update

#SRCHOST="10.3.171.2" #unreachable test
#SRCHOST="10.3.171.246"
SRCHOST="bun.local"
SRCDIR=$SRCHOST":/cygdrive/c/mbrlspci"

SRCFILESSPACE="Makefile do-version.sh init-asap.nasm common-asap.nasm common.ninc "
#
# http://ajhaupt.blogspot.com/2010/12/create-comma-separated-string-in-shell.html
SRCFILESCOMMA=""
for f in $SRCFILESSPACE; do
  SRCFILESCOMMA="${SRCFILESCOMMA:-}${SRCFILESCOMMA:+,}${f}"
done
#echo $SRCFILESCOMMA

# Copy files from bun.local
#$FPING $FPINGOPTS $SRCHOST >& /dev/null
#if [ $? -eq 0 ]; then
#  echo $RSYNC $RSYNCOPTS $SRCDIR/{$SRCFILESCOMMA} .
#  $RSYNC $RSYNCOPTS $SRCDIR/{$SRCFILESCOMMA} .
#else
#  echo $SRCHOST" is unreachable"
#fi

echo chmod 644 $SRCFILESSPACE
chmod 644 $SRCFILESSPACE

make spotless
make

cp mbrlspci.img qemu-dbg/hda-contents/


#SRCHOST="192.168.254.254" #unreachable test
SRCHOST="pixi" #tftp server
$FPING $FPINGOPTS $SRCHOST >& /dev/null
if [ $? -eq 0 ]; then
  echo $RSYNC $RSYNCOPTS mbrlspci.img $SRCHOST:/var/lib/tftpboot/mbrlspci/
  $RSYNC $RSYNCOPTS mbrlspci.img $SRCHOST:/var/lib/tftpboot/mbrlspci/
else
  echo $SRCHOST" is unreachable"
fi

: '
SRCHOST="xp-vm" #win
$FPING $FPINGOPTS $SRCHOST >& /dev/null
if [ $? -eq 0 ]; then
  MNTDIR=/mnt/smb0
  if [ ! -d $MNTDIR ]; then
    sudo mkdir $MNTDIR
  fi
  sudo mount -t cifs -o username=user,password=password //bun/Share $MNTDIR
  sudo cp -v mbrlspci.img $MNTDIR/mbrlspci/
  sudo umount $MNTDIR
else
  echo $SRCHOST" is unreachable"
fi
'


. updatembrlspci.sh mbrlspci.img
