#!/bin/bash
echo  0 >| notify/gtc.notify
cp gtc.input.orig gtc.input
mpiexec -n 8 -hostfile host_file ./gtc 

