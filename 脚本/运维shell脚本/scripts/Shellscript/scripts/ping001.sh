#!/usr/bin/bash
ip=10.18.42.1

i=1
while [ $i -le 5 ]
do
	ping -c1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip is up..."
	fi
	let i++
done
