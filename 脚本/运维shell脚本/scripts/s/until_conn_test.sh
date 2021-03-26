#!/bin/bash
#
#
until ping -c1 -W1 $ip &>/dev/null
do
	sleep 1
done
echo "$ip is up"
