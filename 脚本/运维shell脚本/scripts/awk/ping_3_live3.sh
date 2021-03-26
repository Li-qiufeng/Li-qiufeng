#!/bin/env bash
$ping count 3
ping_sucess(){
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ]; then
		echo "$ip is ok"
		continue
	fi
	}
while read ip
do
	ping_success
	ping_success
	ping_success
	echo "$ip ping is failure"
done < ip.txt
