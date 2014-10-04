#!/bin/bash
cp gtc.input.restart gtc.input
cp history_restart.out history.out
cp sheareb_restart.out sheareb.out
mpiexec -n 2 ./gtc

