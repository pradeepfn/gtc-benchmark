#!/bin/bash
make restartclean
echo  0 >| notify/gtc.notify
cp gtc.input.orig gtc.input
#mpiexec -n 48 -hostfile host_file ./gtc > gtc.log 2>&1 
mpiexec -n 4 ./gtc 

