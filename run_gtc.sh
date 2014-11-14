#!/bin/bash

echo  0 >| notify/gtc.notify
cp gtc.input.orig gtc.input
mpirun -n 4 -hostfile host_file ./gtc

