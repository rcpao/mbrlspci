#!/bin/bash

# Manually modify MAJOR_VERSION, MINOR_VERSION, and BUG_VERSION:
MAJOR_VERSION=0
MINOR_VERSION=0
BUG_VERSION=1

## http://stackoverflow.com/questions/579196/getting-the-last-revision-number-in-svn
##SVN_REVISION=`svn info -r 'HEAD' | grep "Last Changed Rev:" | egrep -o "[0-9]+"`
#SVN_REVISION=`svn info | grep "Last Changed Rev:" | egrep -o "[0-9]+"`
#
#echo "VERSION_STR = \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION"\""


OUT=version.inc
echo ";$OUT for MASM compatible assemblers, created by do-version.sh" > $OUT
#echo "BIOS_VERSION_WORD = "$VERSION >> $OUT
echo "MAJOR_VERSION_WORD = "$MAJOR_VERSION >> $OUT
echo "MINOR_VERSION_WORD = "$MINOR_VERSION >> $OUT
echo "BUG_VERSION_WORD = "$BUG_VERSION >> $OUT
echo "VERSION_STR = \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"\"" >> $OUT #untested in JWasm
#echo "SVNREVISION_DWORD = "$SVN_REVISION >> $OUT
#echo "VERSION_STR = \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION"\"" >> $OUT #untested in JWasm

OUT=version.ninc
echo ";$OUT for Netwide Assembler (NASM), created by do-version.sh" > $OUT
#echo "BIOS_VERSION_WORD equ "$VERSION >> $OUT
echo "MAJOR_VERSION_WORD equ "$MAJOR_VERSION >> $OUT
echo "MINOR_VERSION_WORD equ "$MINOR_VERSION >> $OUT
echo "BUG_VERSION_WORD equ "$BUG_VERSION >> $OUT
echo "%define VERSION_STR \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"\"" >> $OUT
# echo "SVNREVISION_DWORD equ "$SVN_REVISION >> $OUT
# echo "%define VERSION_STR \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION"\"" >> $OUT

OUT=version.h
: <<'comment_end'
echo "/* $OUT for C, created by do-version.sh */" > $OUT
echo "#define MAJOR_VERSION_WORD "$MAJOR_VERSION >> $OUT
echo "#define MINOR_VERSION_WORD "$MINOR_VERSION >> $OUT
echo "#define BUG_VERSION_WORD "$BUG_VERSION >> $OUT
echo "#define VERSION_STR \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"\"" >> $OUT
# echo "#define SVNREVISION_DWORD "$SVN_REVISION >> $OUT
# echo "#define VERSION_STR \""$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION"\"" >> $OUT
comment_end

# export MBR_FILE_NAME="mbr.img-"$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION
# export STAGE1_FILE_NAME="stage1.img-"$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_VERSION"."$SVN_REVISION


IN=perm.img
if [ -f $IN ]; then
  OUT=permsize.ninc
  #http://stackoverflow.com/a/1816466
  PERMLS=($(ls -ln $IN)) #bash array
  #PERMLS=(`ls -ln $IN`) #bash array
  echo PERMLS=${PERMLS[@]}
  i=0
  for tok in "${PERMLS[@]}"; do
    echo "  " PERMLS[$i]=$tok
    i=$(($i + 1))
  done
  PERMSIZE=${PERMLS[4]}
  echo "PERMSIZE equ $PERMSIZE" 
  echo "PERMSIZE equ $PERMSIZE" > $OUT
fi

exit
