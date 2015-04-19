#!/bin/bash


# fedora prerequisites
# yum install vim-common #for xxd


# http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
for CMD in xxd
do
  command -v $CMD >/dev/null 2>&1 || { echo >&2 "$CMD is not installed.  Aborting."; exit 1; }
done


BOOTLOADERIMG=$1
if [ "$1" = "" ]; then
  BOOTLOADERIMG=mbr.img
fi
echo "BOOTLOADERIMG=$BOOTLOADERIMG"


BOOTLOADERSIZE=$(stat -c%s $BOOTLOADERIMG)
echo BOOTLOADERSIZE=$BOOTLOADERSIZE
BOOTLOADERBLOCKS=$(expr \( $BOOTLOADERSIZE + 511 \) / 512)
echo BOOTLOADERBLOCKS=$BOOTLOADERBLOCKS


# dd $BOOTLOADERIMG to known drives
function ddbootloader {
  # $1 = destination block device
  if [ -b $1 ]; then
    echo $1

    MBRSIG=$(sudo xxd -ps -s +0x1FE -l 2 $1)
    echo MBRSIG=$MBRSIG
    if [ "$MBRSIG" != "55aa" ]; then
      echo "MBR signature not found (is this GPT?).  Ignoring this device."
      return 1
    fi

    # GPTSIG=$(sudo xxd -ps -s +0x200 -l 8 $1)
    GPTSIG=$(sudo xxd -g 1 -s +0x200 -l 8 $1)
    echo GPTSIG=$GPTSIG
    # if [ "$GPTSIG" = "4546492050415254" ]; then
    if [ "$GPTSIG" = "0000200: 45 46 49 20 50 41 52 54                          EFI PART" ]; then
      echo "GPT signature found.  Ignoring this device."
      return 1
    fi

    sudo dd if=$BOOTLOADERIMG of=$1
  fi
  return 0
}


# dd $BOOTLOADERIMG to known drives while preserving existing 
# UEFI disk signature and partition table entries
UPDDIR=updatebootloader_backups
if [ ! -d $UPDDIR ]; then
  sudo mkdir $UPDDIR
fi
function updatebootloader {
  # $1 = destination block device
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  UPDFS=$UPDDIR/$TIMESTAMP-$(basename $1).dd
  # echo $1 $TIMESTAMP $UPDFS
  if [ -b $1 ]; then
    echo $1

    MBRSIG=$(sudo xxd -ps -s +0x1FE -l 2 $1)
    echo MBRSIG=$MBRSIG
    if [ "$MBRSIG" != "55aa" ]; then
      echo "MBR signature not found (is this GPT?).  Ignoring this device."
      return 1
    fi

    # GPTSIG=$(sudo xxd -ps -s +0x200 -l 8 $1)
    GPTSIG=$(sudo xxd -g 1 -s +0x200 -l 8 $1)
    echo GPTSIG=$GPTSIG
    # if [ "$GPTSIG" = "4546492050415254" ]; then
    if [ "$GPTSIG" = "0000200: 45 46 49 20 50 41 52 54                          EFI PART" ]; then
      echo "GPT signature found.  Ignoring this device."
      return 1
    fi

    # Backup original bootier sectors
    sudo dd if=$1 of=$UPDFS bs=512 count=$BOOTLOADERBLOCKS

    # dd bootloader
    sudo dd if=$BOOTLOADERIMG of=$1

    # Restore original UEFI disk signature and partition table entries
    # 1B8h = 440, 200h - 1B8h = 48h = 72
    sudo dd if=$UPDFS of=$1 bs=1 skip=440 seek=440 count=72


    # DBG Replace UEFI disk signatures + partition table entries
    #sudo dd if=$UPDDIR/20140519-111313.dd of=$1 bs=1 skip=440 seek=440 count=72

    # DBG Replace bootloader
    #sudo dd if=$UPDDIR/20140523-100320-ata-KINGSTON_SSDNOW_30GB_30GS10L6T84Z.dd of=$1 

  fi
}


# $ udevadm info --query=property --path=/sys/block/sda

# "SwTier CentOS 6.5 64-bit" VMware guest
if [ `hostname` == "centos6-vm.local" ]; then
  # Linux centos6-vm.local 2.6.32-431.5.1.el6.x86_64 #1 SMP Wed Feb 12 00:41:43 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
  hostname
  #ddbootloader /dev/disk/by-id/usb-Toshiba_3.5_External_Har_YB036316DN00-0:0 #Samsung SP2004C in CentOS 6.5
  #updatebootloader /dev/sdb #ESXi 5.5 tpage_size=4MB
  #updatebootloader /dev/sdc #ESXi 5.5 tpage_size=1MB
  #updatebootloader /dev/sdd #ESXi 5.5 tpage_size=512KB
fi

# "ub14-vb" VirtualBox v4.3.12 guest of rc.ub14.bun.rs.paonet.org
if [ `hostname` == "ub14-vb" ]; then
  hostname
  # updatebootloader /dev/disk/by-id/ata-VBOX_HARDDISK_VBff9fd71f-8a90826a #.vdi cross-mounted from ub14-vb1 # GRUB2?
  # updatebootloader /dev/disk/by-id/ata-VBOX_HARDDISK_VB034bacb3-4527f19b #.vdi cross-mounted from ros-vb # VBR at sector 69 (0x45).
  #updatebootloader /dev/disk/by-id/ata-VBOX_HARDDISK_VB0199dece-2cd481d8 #.vdi cross-mounted from w81-vb1 # VBR at sector 2048 (byte offset 0x100000).
fi


# Non-hostname specific (e.g. USB drives)

updatebootloader /dev/disk/by-id/usb-Kingston_DataTraveler_G3_001372997BD5EA80C521006E-0:0


if [ -f *.exe ]; then

  MNTDIR=/media/FREEDOS2011
  if [ ! -d $MNTDIR ]; then
    sudo mkdir $MNTDIR
  fi
  sudo mount /dev/sdc1 $MNTDIR
  sudo cp -v *.exe $MNTDIR/
  sleep 2
  sudo umount $MNTDIR


  MNTDIR=/media/DOS_C
  if [ ! -d $MNTDIR ]; then
    sudo mkdir $MNTDIR
  fi
  sudo mount /dev/sdb1 $MNTDIR
  sudo cp -v *.exe $MNTDIR/
  sleep 2
  sudo umount $MNTDIR

fi


sync
