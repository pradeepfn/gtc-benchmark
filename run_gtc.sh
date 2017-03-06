#!/bin/bash
make restartclean
echo  0 >| notify/gtc.notify
cp gtc.input.orig gtc.input
#cp phoenix.config.run phoenix.config
#mpiexec -n 16 -hostfile host_file ./gtc > gtc.log 2>&1 
#mpiexec -n 16 -hostfile host_file ./gtc 
mpirun -np 16 --bind-to core ../phoenix/bin/mpiformat /dev/shm 100
mpirun -np 16  --bind-to core ./gtc 
#mpiexec -n 4 ./gtc 

