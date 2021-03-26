#!/usr/bin/bash
ip=10.18.42.1

ping -c1 $ip &>/dev/null
if [ $? -eq 0 ]; then
	echo "$ip is up."
else
	echo "$ip is down."
fi
