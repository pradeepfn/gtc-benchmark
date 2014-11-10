#!/bin/bash

echo 'Preparing to run tests on checkpoint library'
echo 'cleaning up lock files and ramdisk files'
make restartclean
make clean
make
echo "done compiling, running test_write"
./test_write &
child_pid=$!
echo "write child process id :  $!"
sleep 5s
echo "Killing the child process after 5 seconds..."
kill -SIGTERM $child_pid
./test_read &
rchild_pidone=$!
echo "read child process id : $!"
sleep 6s
echo "killing the read child process after 6 seconds..."
kill -SIGTERM $rchild_pidone
./test_read &
rchild_pidtwo=$!
echo "read child process id : $!"
sleep 6s
echo "killing the read child process after 6 seconds..."
kill -SIGTERM $rchild_pidtwo
echo "done running test suite..."
