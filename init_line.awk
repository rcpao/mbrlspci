
# from
# 826, "EBDA allocation error"
# to
# https://github.com/rcpao/UefiRamDisk/blob/6681962fd955cebdfaff26ecda9cc39136bca5d3/BlankDrv/BlankDrv.c#L41

BEGIN {
  FS = ", ";
}

{printf "https://github.com/rcpao/UefiRamDisk/blob/%s/BlankDrv/BlankDrv.c#L41%s\n", GIT_HASH, $1;}

END {
  #eights=888;
  #print "eights=" eights;
  #printf "eights=%s\n", eights;

  printf "GIT_HASH=%s\n", GIT_HASH;
}
