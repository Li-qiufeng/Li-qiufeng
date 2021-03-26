#!/bin/env bash
ip_list()
        {
	if [ ! -d $PWD/tmp ]; then
                mkdir $PWD/tmp
        fi
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
open_vm(){
        if [ ! -s $PWD/tmp/ip.txt ]; then
                for i in {1..5}
                do
                        virsh start centos7u3-$i &> /dev/null
                done
                echo "Switch on, please wait..."
                sleep 30
        fi
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
	rm -rf /tmp/jump_host/*
        for ip in $(cat $PWD/tmp/ip.txt)
        do
	if [ ! -f /tmp/jump_host/$ip.txt ];then
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
	fi
        echo "$ip_$(date +%F-%H) Upload key successful" > /tmp/jump_host/$ip.txt
        done
	}

conf_file(){
	prefix=centos7u3-
	for i in {1..5}
	do
	>$PWD/tmp/$prefix$i.conf
	>$PWD/tmp/$prefix$i.sh
	cat>> $PWD/tmp/$prefix$i.conf <<-EOF
		<VirtualHost *:80>
		        ServerName www.$prefix$i.com
		        ServerAlia $prefix$i.com
		        DocumentRoot "/webdata/www/html"
		</VirtualHost>
		
		<Directory "/webdata/www/html">
		        Require all grated
		</Directory>
	EOF
	cat>> $PWD/tmp/$prefix$i.sh <<-EOF
	#!/bin/env bash
	sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config 
	setenforce 0
	mkdir -p /webdata/www/html
	yum -y install httpd	
	        systemctl start httpd
	        systemctl enable httpd
	firewall-cmd --permanent --add-service=http
	firewall-cmd --permanent --add-service=https
	firewall-cmd --reload
	systemctl restart httpd
	EOF
	done
	for ip in $(cat $PWD/tmp/ip.txt)
	do
		scp $PWD/tmp/$prefix$i.conf $ip:/etc/httpd/conf.d/
		scp $PWD/tmp/$prefix$i.sh $ip:$PWD/
		ssh $ip "bash $PWD/$prefix$i.sh"
		ssh $ip "mkdir -p /webdate/www/html"
		ssh $ip "echo 'hello, is test...' > /webdate/www/html/index.html"
		ssh $ip "chown -R apache.apache /webdate/www/html/*"
	done
	}
ip_list
open_vm
ip_list
push_sshkey
conf_file
