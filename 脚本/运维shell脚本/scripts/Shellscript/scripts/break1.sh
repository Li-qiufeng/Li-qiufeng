#!/usr/bin/bash
for i in {A..D}
do
	echo -n $i
	for j in {1..9}
	do
		if [ $j -eq 5 ];then
			break
		fi
		echo -n $j
	done
	echo
done
