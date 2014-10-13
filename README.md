gtc
===

Gyrokinetic Toroidal Code, Version 1, 2002. Original code location : http://phoenix.ps.uci.edu/GTC/codes.php

Running
-------------

1. create a ramdisk
	mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk
2. make
3. run_gtc.sh

restart
------------


1. irun in gtc.input should be set to 1
2. history_restart.out should be renamed to history.out
3. shearab_restart.out should be renamed to shearab.out 


Convenience script >> restart_gtc.sh
(replaces the above files and run gtc)
