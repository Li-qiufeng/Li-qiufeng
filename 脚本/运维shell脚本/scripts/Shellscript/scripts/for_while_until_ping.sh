#!/usr/bin/bash
for i in {2..254}
do
	{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip up."
	fi
	}&
done
wait
echo "all finish..."
