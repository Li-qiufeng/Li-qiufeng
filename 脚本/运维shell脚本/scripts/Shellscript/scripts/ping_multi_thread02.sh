#!/usr/bin/bash
#ping02 multi thread
#v1.0 by tianyun
thread=10
tmp_fifofile=/tmp/$$.fifo

mkfifo $tmp_fifofile
exec 8<> $tmp_fifofile
rm $tmp_fifofile

for i in `seq $thread`
do
	echo >&8
done

for i in {1..254}
do
	read -u 8
	{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip is up."
	else
		echo "$ip is down"
	fi
	echo >&8
	}&
done
wait
exec 8>&-
echo "all finish..."
