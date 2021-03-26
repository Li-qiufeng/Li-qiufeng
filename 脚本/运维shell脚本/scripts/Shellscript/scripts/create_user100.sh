#!/usr/bin/bash
#v1.0 by tianyun
while :
do
	read -p "Please enter prefix & pass & num[tianyun 123 5]: " prefix pass num
	printf "user infomation:
	----------------------------
	user prefix: $prefix
	user password: $pass
	user number: $num
	----------------------------
	"
	read -p "Are you sure?[y/n]: " action
	if [ "$action" = "y" ];then
		break
	fi
done

for i in `seq -w $num`
do
	user=$prefix$i
	id $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "user $user already exists"
	else
		useradd $user
		echo "$pass" |passwd --stdin $user &>/dev/null
		if [ $? -eq 0 ];then
			echo "$user is created."
		fi	 
	fi
done






