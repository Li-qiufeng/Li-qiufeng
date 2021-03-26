#!/usr/bin/bash
#ping01
for i in {1..254}
do
	{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip is up."
	else
		echo "$ip is down"
	fi
	}&
done
wait
echo "all finish..."
