#!/usr/bin/bash
ping -c1 $1 &>/dev/null
if [ $? -eq 0 ]; then
	echo "$1 is up."
else
	echo "$1 is down."
fi
