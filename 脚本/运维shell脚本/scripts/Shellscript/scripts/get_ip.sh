#!/usr/bin/bash
>ip.txt
password=centos

for i in {2..254}
do
	{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip" >> ip.txt
		/usr/bin/expect <<-EOF
		set timeout 10
		spawn ssh-copy-id $ip
		expect {
			"yes/no" { send "yes\r"; exp_continue }
			"password:" { send "$password\r" }
		}
		expect eof
		EOF
	fi
	}&
done
wait
echo "finish...."
