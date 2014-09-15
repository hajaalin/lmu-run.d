#!/bin/bash
container=$1
if [ -z $container ]; then
	echo "Usage: $0 [container_name|container_id]"
	exit
fi

PID=$(docker inspect --format {{.State.Pid}} $container)
sudo nsenter --target $PID --mount --uts --ipc --net --pid

