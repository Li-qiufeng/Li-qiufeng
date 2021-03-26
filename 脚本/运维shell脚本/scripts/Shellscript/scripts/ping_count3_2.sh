#!/usr/bin/bash
while read ip
do
	fail_count=0	
	for i in {1..3}
	do
		ping -c1 -W1 $ip &>/dev/null
		if [ $? -eq 0 ];then
			echo "$ip ping is ok."
			break
		else
			echo "$ip ping is failure: $i"
			let fail_count++
		fi
	done
	if [ $fail_count -eq 3 ];then
		echo "$ip ping is failure!"
	fi
done <ip.txt
