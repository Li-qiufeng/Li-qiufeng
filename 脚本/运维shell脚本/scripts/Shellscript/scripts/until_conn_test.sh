#!/usr/bin/bash
#v1.0 by tianyun
ip=10.18.42.127
until ping -c1 -W1 $ip &>/dev/null
do
	sleep 1
done
echo "$ip is up."
