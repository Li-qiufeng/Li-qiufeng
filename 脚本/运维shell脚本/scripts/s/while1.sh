#!/bin/bash
#while create user
#v1.0 name time
while read user

do
	id $user &> /dev/null
	if [ $? -eq 0 ];then
		echo "user .."
	else
	useradd $user

		if [ $? -eq 0 ];then
			echo "user $user create"
		fi
	fi
done < user.txt
