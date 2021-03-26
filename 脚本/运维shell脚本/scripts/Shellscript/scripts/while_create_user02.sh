#!/usr/bin/bash
#while create user
#v1.0 by tianyun
while read line
do
	if [  ${#line} -eq 0 ];then
		echo "-------------------------"
		#exit
		#break
		continue
	fi

	user=`echo $line|awk '{print $1}'`	
	pass=`echo $line|awk '{print $2}'`	
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
done < user1.txt

echo "all ok.................."
