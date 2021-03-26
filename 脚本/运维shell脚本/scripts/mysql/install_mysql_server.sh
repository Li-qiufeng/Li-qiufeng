#!/bin/env bash
ip_list()
        {
	ip=192.168.100.
	if [ ! -d $PWD/tmp ]; then
                mkdir $PWD/tmp
        fi
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
        }
open_vm(){
                echo "Switch on, please wait..."
		for i in {1..5}
                do
                        virsh start centos7u3-$i
                done
                sleep 40
        }
push_sshkey()
        {
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
        for ip in $(cat $PWD/tmp/ip.txt)
        do
	if [ ! -f /tmp/jump_host/$ip.txt ];then
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

install_mysql(){
		while read line
		do
			hostname[k++]=$line
		done<hostname.txt
		sed -ri '3,$d' /etc/hosts
		local i=0
		for ip in $(cat $PWD/tmp/ip.txt)
		do
			echo "$ip ${hostname[$i]}">>/etc/hosts
			ssh $ip "echo ${hostname[$i]} > /etc/hostname"
			ssh $ip "hostname ${hostname[$i]}"
			let i=i+1
		done
		for ip in $(cat $PWD/tmp/ip.txt)
		do
			{
			scp /etc/hosts $ip:/etc
			scp $PWD/install_mysql.sh $ip:/root/
			scp $PWD/init_mysql_yum.sh $ip:/root/
			ssh $ip "bash /root/install_mysql.sh"
			}&
		done
		
	}
open_vm
ip_list
push_sshkey
install_mysql
