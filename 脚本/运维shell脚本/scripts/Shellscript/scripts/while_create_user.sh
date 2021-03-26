#!/usr/bin/bash
#while create user
#v1.0 by tianyun
while read user
do
	id $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "user $user already exists"
	else
		useradd $user
		if [ $? -eq 0 ];then
			echo "$user is created."
		fi
	fi
done < user.txt
