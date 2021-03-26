#!/bin/env bash
for i in {1..5}
do
	virsh start centos7u3-$i &> /dev/null
done
echo "Switch on, please wait..."
sleep 30

ip=192.168.100.
>$PWD/tmp/ip.txt
for i in {2..254}
do
	{
	ping -c1 -W1 $ip$i &> /dev/null
	if [ $? -eq 0 ];then
		echo "$ip$i" >> $PWD/tmp/ip.txt
	fi
	}&
done
wait


while read  ip 
        do
                {
		ssh $ip "rm -f /root/2017* init_mysql_yum.sh"
		scp $PWD/init_mysql_yum.sh $ip:/root/
                ssh $ip "bash /root/init_mysql_yum.sh"
                }&
        done<$PWD/tmp/ip.txt

