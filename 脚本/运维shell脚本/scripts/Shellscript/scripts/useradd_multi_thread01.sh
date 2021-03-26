#!/usr/bin/bash
#useradd
for i in {1..100}
do
	{
	user=ttt$i
	useradd $user
	echo "111" |passwd --stdin $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "$user is created."
	fi
	}&
done
wait
echo "finish...."
