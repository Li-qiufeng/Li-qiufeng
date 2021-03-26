#!/bin/bash
#
#
while ping -c1 -W1 $ip &> /dev/null
do
	sleep 2

done
echo "$ip is down"
