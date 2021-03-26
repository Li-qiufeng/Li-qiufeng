#!/usr/bin/bash
#count tcp status
#v1.0 by tianyun

while :
do
unset status
declare -A status
	type=`ss -an |grep :80 |awk '{print $2}'`
	for i in $type 
	do
		let status[$i]++
	done

	for j in ${!status[@]}
	do
		echo "$j: ${status[$j]}"
	done
	sleep 1; clear
done
