gtc
===

Gyrokinetic Toroidal Code, Version 1, 2002. Original code location : http://phoenix.ps.uci.edu/GTC/codes.php


Environment Setup
------------------
 sudo apt-get install libssl-dev
 sudo apt-get install libnetcdf-dev        


Running
-------------

1. create a ramdisk:
	sudo mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk
	sudo chown -R username /mnt/ramdisk
1.a For NVM code, create a ramdisk
	sudo mount -t tmpfs -o size=1G tmpfs /mnt/pvm
	sudo chown -R username /mnt/pvm
2. make
3. run_gtc.sh

restart
------------


1. irun in gtc.input should be set to 1
2. history_restart.out should be renamed to history.out
3. shearab_restart.out should be renamed to shearab.out 


Convenience script >> restart_gtc.sh
(replaces the above files and run gtc)
