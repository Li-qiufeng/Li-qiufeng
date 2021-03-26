#!/usr/bin/bash
read -p "Please input a username: " user

#if id $user &>/dev/null; then

id $user &>/dev/null
if [ $? -eq 0 ]; then
	echo "user $user already exists"
else
	useradd $user
	if [ $? -eq 0 ];then
		echo "$user is created."
	fi
fi
