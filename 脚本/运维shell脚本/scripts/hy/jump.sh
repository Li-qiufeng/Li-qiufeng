#!/usr/bin/bash
#ping all hosts
#create key-gen
>ip.txt
password=centos

rpm -q expect &>/dev/null
if [ $? -ne 0 ];then
	echo "install expect"
	yum -y install expect &>/dev/null
fi
if [ ! -f ~/.ssh/id_rsa ];then
	echo "create ssh-keygen"
	ssh-keygen -P "" -f ~/.ssh/id_rsa
fi
for i in {2..254}
do
{
	ip=192.168.122.$i
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		echo "$ip" >> ip.txt
		/usr/bin/expect	<<-EOF
		spawn ssh-copy-id root@$ip
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
echo ok..
