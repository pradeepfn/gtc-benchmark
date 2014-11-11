#!/bin/bash

NUM_PROCESS=2
SLEEP_TIME=10


function start_gtc() {
	cp gtc.input.orig gtc.input
	mpirun -n $NUM_PROCESS ./gtc > gtc.log 2>&1  &
	#mpirun -n $NUM_PROCESS ./gtc &
	pid=$!
	sleep $SLEEP_TIME
}

function restart_gtc(){
	echo "restarting gtc..."
	sed -i "s/irun=0/irun=1/" gtc.input
	cp history_restart.out history.out
	cp sheareb_restart.out sheareb.out
	mpirun -n $NUM_PROCESS ./gtc >> gtc.log 2>&1  &
	#mpirun -n $NUM_PROCESS ./gtc &
	pid=$!
	sleep $SLEEP_TIME
}

function kill_gtc(){
	echo "killing gtc using kill command"
	kill -SIGTERM $1 > /dev/null 2>&1
	test=$?
	return $test
}

echo "cleaning artifacts from the previous run"
make restartclean

echo "starting the gtc program"
start_gtc
kill_gtc $pid
if [ $? -ne 0 ]
	then
		echo "gtc program not running anymore... exiting "
		exit 0
fi

while
	restart_gtc 
	kill_gtc $pid
	[ $? -eq 0 ]
do
	:
done

echo "gtc program not running anymore... exiting "
exit 0
