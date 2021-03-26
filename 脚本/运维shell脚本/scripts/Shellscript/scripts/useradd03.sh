#!/usr/bin/bash
###############################################
#useradd				      #
#v1.0 by tianyun 29/8/2017		      #
###############################################
read -p "Please input number: " num

while true
do
	if [[ "$num" =~ ^[0-9]+$ ]];then
		break	
	else
		read -p "不是数字，请重新输入数值: " num
	fi
done

read -p "Please input prefix: " prefix
while true
do
	if [ -n "$prefix" ];then
		break
	else
		read -p "Please input prefix: " prefix
	fi
done

for i in `seq $num`
do
	user=$prefix$i
	useradd $user
	echo "123" |passwd --stdin $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "$user is created."
	fi
done
