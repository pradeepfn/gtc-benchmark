#!/bin/bash
echo "creating ramdisks in localhost..."
mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk
chown -R pradeep /mnt/ramdisk
mount -t tmpfs -o size=1G tmpfs /mnt/pvm
chown -R pradeep /mnt/pvm
