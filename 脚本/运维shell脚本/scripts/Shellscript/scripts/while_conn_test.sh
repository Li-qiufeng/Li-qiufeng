#!/usr/bin/bash
ip=10.18.42.127
while ping -c1 -W1 $ip &>/dev/null
do
	sleep 1	
done
echo "$ip is down!"
