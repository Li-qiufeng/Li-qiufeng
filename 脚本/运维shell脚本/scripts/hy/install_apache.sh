#!/usr/bin/bash
while :
do
num=0
for ip in `cat ip.txt`
do
	ip[++num]=$ip
	echo -e "\t$num: $ip"
	scp install.sh $ip:/root &>/dev/null
done

read -p "Enter num: " addr
if [[ $addr =~ ^[0-9]+$ ]];then
case $addr in 
$addr)
	ssh root@${ip[$addr]} bash install.sh
	
esac
else
	echo "reenter"
fi
done
