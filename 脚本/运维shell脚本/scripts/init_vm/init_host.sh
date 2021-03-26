#!/bin/bash
#coding:utf-8
open_vm(){
                echo "Switch on, please wait..."
                for i in {5..9}
                do
                        virsh start centos7u3-$i
                done
                sleep 40
        }

ping_test(){
>$PWD/ip.txt
for i in {2..254}
do
	{
	ping -c1 192.168.100.$i> /dev/null
	if [ $? -eq 0 ];then
		echo "192.168.100.$i" >> $PWD/ip.txt
	fi
	}&	
done
}
pull_key(){
	password=centos
	rpm -q expect &> /dev/null
	if [ $? -ne 0 ]; then
		echo "Installing, please wait a moment"
		yum -y installl expect &> /dev/null
		if [ $? -eq 0 ];then
			echo "installation is complete"
		else
			echo "Installation failure"
			exit 1
		fi
	fi
	if [ ! -f ~/.ssh/id_rsa ]; then
		ssh-keygen -P "" -f ~/.ssh/id_rsa
	fi
	sed -ri '2,$d' /root/.ssh/known_hosts
	for ip in $(cat $PWD/ip.txt)
	do
	if [ ! -f /$PWD/$ip.txt ];then
		/usr/bin/expect <<-EOF
		set timeout 10
		#log_user 0
		spawn ssh-copy-id $ip
		expect {
			"yes/no" {send "yes\r"; exp_continue}
			"password:" {send "$password\r"}
			}
		expect eof
		EOF
	fi
	done
	}
set_hosts_hostname(){
	while read line
	do
		hostname[k++]=$line
	done <hostname.txt
	echo ${hostname[@]}
	sed -ri '3,$d' /etc/hosts
	i=0
	for ip in $(cat $PWD/ip.txt)
	do
	echo "$ip ${hostname[$i]}">>/etc/hosts
	ssh $ip "hostnamectl set-hostname ${hostname[$i]}"
	ssh $ip "hostname ${hostname[$i]}"
	let i=i+1
	done
	unset i
	}
pull_key_hostname(){
for name in $(cat $PWD/hostname.txt)
do
/usr/bin/expect <<-EOF
spawn ssh-copy-id $name
expect {
	"yes/no" {send "yes\r";exp_continue}
	}
	expect eof
	EOF
	scp /etc/hosts $name:/etc
	ssh $name "systemctl stop firewalld.service"
	ssh $name "systemctl disable firewalld.service"
done
	}
conn_host(){
for name in $(cat $PWD/hostname.txt)
do 
	name[++i]=$name
done
echo ${name[@]}
gnome-terminal --window -e "ssh ${name[1]}" --tab -e "ssh ${name[2]}" --tab -e "ssh ${name[3]}" --tab -e "ssh ${name[4]}" --tab -e "ssh ${name[5]}"
	}
open_vm
ping_test
pull_key
set_hosts_hostname
pull_key_hostname
conn_host
