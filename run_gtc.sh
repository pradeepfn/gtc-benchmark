#!/bin/bash
make restartclean
rm -rf stats/.*	
echo  0 >| notify/gtc.notify
cp gtc.input.orig gtc.input
#cp phoenix.config.run phoenix.config
#mpiexec -n 16 -hostfile host_file ./gtc > gtc.log 2>&1 
#mpiexec -n 16 -hostfile host_file ./gtc 
mpirun -np 16 --bind-to core ../phoenix/bin/mpiformat /dev/shm 1000
mpirun -np 16  ./gtc 
#mpiexec -n 4 ./gtc 

