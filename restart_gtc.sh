#!/bin/bash
cp gtc.input.orig gtc.input
sed -i "s/irun=0/irun=1/" gtc.input
cp history_restart.out history.out
cp sheareb_restart.out sheareb.out
mpirun -n 4 ./gtc

