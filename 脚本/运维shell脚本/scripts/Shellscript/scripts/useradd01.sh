#!/usr/bin/bash
###############################################
#useradd				      #
#v1.0 by tianyun 29/8/2017		      #
###############################################
read -p "Please input number: " num
read -p "Please input prefix: " prefix

for i in `seq $num`
do
	user=$prefix$i
	useradd $user
	echo "123" |passwd --stdin $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "$user is created."
	fi
done
