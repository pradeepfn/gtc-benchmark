#!/bin/bash

NUM_PROCESS=8
SLEEP_TIME=20
IPC_FILE="notify/gtc.notify"

function start_gtc() {
	cp gtc.input.orig gtc.input
	#mpirun -n $NUM_PROCESS ./gtc > gtc.log 2>&1  &
	mpirun -n $NUM_PROCESS -hostfile host_file ./gtc &
	pid=$!
	sleep $SLEEP_TIME
}

function restart_gtc(){
	echo "restarting gtc..."
	sed -i "s/irun=0/irun=1/" gtc.input
	cp history_restart.out history.out
	cp sheareb_restart.out sheareb.out
	#mpirun -n $NUM_PROCESS ./gtc >> gtc.log 2>&1  &
	mpirun -n $NUM_PROCESS -hostfile host_file ./gtc &
	pid=$!
	sleep $SLEEP_TIME
}

function kill_gtc(){
    #setting the flag on shared file
    echo 1 >| $IPC_FILE
    LTIME=`stat -c %X $IPC_FILE`
    while true    
    do
        NTIME=`stat -c %X $IPC_FILE`
        if [[ "$NTIME" != "$LTIME" ]]
        then        
            echo "gtc program has terminted, continue to restart.."
            break
        fi
		#sleep 10 milis
        sleep 0.01 
    done
	#setting the file back to 0 before exiting
	echo 0 >| $IPC_FILE
    return 0
}

echo "cleaning artifacts from the previous run"
make restartclean
echo 0 >| $IPC_FILE
echo "starting the gtc program"
start_gtc
kill_gtc

while
	restart_gtc 
	kill_gtc
	[ $? -eq 0 ]
do
	:
done

echo "gtc program not running anymore... exiting "
exit 0
