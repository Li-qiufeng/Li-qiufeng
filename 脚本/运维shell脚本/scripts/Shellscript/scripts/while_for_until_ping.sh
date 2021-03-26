#!/usr/bin/bash
i=2
while [ $i -le 254 ]
do
	{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip up."
	fi
	}&
	let i++
done
wait
echo "all finish..."
