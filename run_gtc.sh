#!/bin/bash
cp gtc.input.orig gtc.input
mpirun -n 4 -hostfile host_file ./gtc

