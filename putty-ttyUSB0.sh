# minicom and seyon do not assert CTS?  putty works.
#service modemmanager stop
putty -serial /dev/ttyUSB0 -sercfg 8,1,115200,n,R &
