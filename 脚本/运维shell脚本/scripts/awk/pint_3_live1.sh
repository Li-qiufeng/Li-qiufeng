#!/bin/bash
while read ip
do
	for count in {1..3}
	do
		ping -c1 -W1 $ip &>/dev/null
		if [ $? -eq 0 ]; then
			echo "$ip pint is ok"
			break
		else
			echo "$ip ping is failure:$count"
			fail_count[$count]=$ip
		fi
	done
	if [ ${#fail_count[*]} -eq 3 ]; then
		echo "${fail_count[1]} pint is failure"
		unset fail_count[*]
	fi
done<ip.txt
