#!/bin/env bash
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
	local old_key_ip=$(awk -F" " -v key_ip=$1 '{if($1==key_ip){print $1}}' $HOME/.ssh/known_hosts)
	if [ "$old_key_ip" == '' ]; then
		/usr/bin/expect <<-EOF
		set timeout 10
		log_user 1
		log_file $PWD/tmp/push_key_chack.log
		spawn ssh-copy-id $1
		expect {
		"yes/no" {send "yes\r"; exp_continue}
		"password:" {send "$password\r"}
		}
		expect eof
		EOF
    	fi
	}
delect_ssh_key()
	{
	echo $(awk -F" " '{print $1}' $HOME/.ssh/known_hosts)| awk '{len=split($0,a);for(i=1;i<=len;i++)printf "\033[1;31m\t"i": " a[i] "\033[0m\n"}'
	echo -en "\e[1;31mDelete the specified SSH key：\e[0m" 
	read old_ssh_key
	sed -ri '//d' known_hosts
	}
