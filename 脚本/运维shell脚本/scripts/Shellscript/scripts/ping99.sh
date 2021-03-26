#!/usr/bin/bash
#ping check

>ip.txt

ip=192.168.122.2
ping -c1 -W1 $ip &>/dev/null
if [ $? -eq 0 ];then
	echo "$ip" |tee -a ip.txt
fi

