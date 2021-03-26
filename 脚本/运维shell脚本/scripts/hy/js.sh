#!/usr/bin/bash
while :
do
num=0
for ip in `cat ip.txt`
do
	ip[++num]=$ip
	echo -e "\t$num: $ip"
done

read -p "Enter num: " addr

if [[ $addr =~ ^[0-9]+$ ]];then
	ssh root@${ip[$addr]} 2>/dev/null
	if [ ! $? -eq 0 ];then
		echo "No route to host"
	fi
elif [ $addr = "q" ];then
	exit
else
	echo "enter a number"
fi
done
