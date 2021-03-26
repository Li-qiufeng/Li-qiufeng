#!/bin/bash
for i in {2..254}
do 
	{
	ip=
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip up"

	fi
	}&
done
wait
echo "all finish"
i=2
while [ $i -le 254 ]
do 
	{
	ip=
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip up"

	fi
	}&
	let i++
done
wait
echo "all finish"

until [ $i -gt 254 ]
do 
	{
	ip=
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip up"

	fi
	}&
	let i++
done
wait
echo "all finish"
