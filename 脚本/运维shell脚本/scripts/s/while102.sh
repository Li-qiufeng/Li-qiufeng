#!/bin/bash
#while create user
#v1.0 name time
while read line

do	if [ ${$line} -eq 0 ]:then
		continue
	fi
	user=$(echo $line | awk '{print $1}')
	pass=$(echo $line | awk '{print $2}')
	id $user &> /dev/null
	if [ $? -eq 0 ];then
		echo "user .."
	else
	useradd $user
	echo "$pass" | passwd --stdin $user &>/dev/null
		if [ $? -eq 0 ];then
			echo "user $user create"
		fi
	fi
done < user.txt
