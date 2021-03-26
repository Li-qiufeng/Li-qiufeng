#!/bin/bash
#jump host login
#v1.0
#outhor luoyinsheng
#2017-08-31
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
	for ip in $(cat $PWD/tmp/ip.txt)
	do
	/usr/bin/expect <<-EOF
        set timeout 10
	log_user 0
	spawn ssh-copy-id $ip
	expect {
		"yes/no" {send "yes\r"; exp_continue}
		"password:" {send "$password\r"}
		}
	expect eof
	EOF
	echo "$ip_$(date +%F-%H) Upload key successful" > $PWD/tmp/$ip.txt
	done
	}
ip_list()
	{
	>$PWD/tmp/ip.txt
	for i in {2..254}
	do
		{
		ip=192.168.122.$i
		ping -c1 -W1 $ip &> /dev/null
		if [ $? -eq 0 ];then
			echo "$ip" >> $PWD/tmp/ip.txt
		fi
		}&
	done
	wait	
	}

menu() 
	{
	echo -e "\e[1;34m#############################################\e[0m"
	echo -e "\e[1;34m#                                           #\e[0m"
	num=1
	for i in $(cat $PWD/tmp/ip.txt)
	do
	echo -e "\e[1;34m#           $num. $i  	    #\e[0m"
		let num++
	done
	echo -e "\e[1;34m#           q. Quit           		    #\e[0m"
	echo -e "\e[1;34m#                                           #\e[0m"
	echo -e "\e[1;34m#############################################\e[0m"
	}

sign_in() 
	{
	for ip in $(cat $PWD/tmp/ip.txt)
	do
		if [ ! -f $PWD/tmp/$ip.txt ];then
			push_sshkey
		fi
	done
	}
ip_list
if [ ! -s $PWD/tmp/ip.txt ]; then
        for i in {1..5}
        do
                virsh start centos7u3-$i &> /dev/null
        done
	echo "Switch on, please wait..."
	sleep 30
fi
ip_list
menu
sign_in
while :
do
	echo -en "\e[1;32mPlease input connect host [1\2..]: \e[0m"
	read host
	if [ "$host" = "q" ]; then
		exit 0
	else
		echo -en "\e[1;32mPlease input username: \e[0m"
		read user
	fi
	case $host in
		1)
			ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==1)print $0;}')
			ssh $user@$ip
			;;
		2)
			ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==2)print $0;}')
			ssh $user@$ip
			;;
 	        3)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==3)print $0;}')
                        ssh $user@$ip
                        ;;

  		4)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==4)print $0;}')
                        ssh $user@$ip
                        ;;
  		5)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==5)print $0;}')
                        ssh $user@$ip
                        ;;
  		6)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==6)print $0;}')
                        ssh $user@$ip
                        ;;
  		7)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==7)print $0;}')
                        ssh $user@$ip
                        ;;
  		8)
                        ip=$(cat $PWD/tmp/ip.txt |awk '{if(NR==8)print $0;}')
                        ssh $user@$ip
                        ;;
		q)
			break
			;;
		'')
			;;
		*)	
			echo "Input errer,reenter"
	esac
done	
		













	
