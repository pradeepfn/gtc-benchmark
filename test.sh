#!/bin/bash


function kill_gtc(){
	#setting the flag on shared file
	echo 1 > notify/gtc.notify
	LTIME=`stat -c %Z notify/gtc.notify`
	while true    
	do
		NTIME=`stat -c %Z notify/gtc.notify`

		if [[ "$NTIME" != "$LTIME" ]]
		then    
			echo "gtc program has terminted, continue to restart.."
			break
		fi
		sleep 0.1
	done
	return 0
}

kill_gtc
exit 0



