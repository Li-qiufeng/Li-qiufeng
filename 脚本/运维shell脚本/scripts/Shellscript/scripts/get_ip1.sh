#!/usr/bin/bash
>ip.txt
password=centos

rpm -q expect &>/dev/null
if [ $? -ne 0 ];then 
	yum -y install expect
fi

if [ ! -f ~/.ssh/id_rsa ];then
	ssh-keygen -P "" -f ~/.ssh/id_rsa
fi

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
