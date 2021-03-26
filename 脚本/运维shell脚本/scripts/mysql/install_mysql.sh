#!/bin/env bash
#install mysql 5.7.19
#
#name time
	sed -ri '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
	setenforce 0
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	#firewall-cmd --permanent --add-service=mysql
	#firewall-cmd --reload 

	rpm -q wget
	if [ $? -ne 0 ]; then
		yum -y install wget >/dev/null
	fi
	wget ftp://192.168.100.1/mysql.repo -P /etc/yum.repos.d/
	#yum -y install https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
	yum repolist

	yum -y install mysql-community-server.x86_64
	systemctl start mysqld
	systemctl enable mysqld

	tempassword=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
	newpassword="My5719@passwd"
	mysqladmin -uroot -p"$tempassword" password "$newpassword"
	
	mkdir /var/log/mysql
	chown -R mysql.mysql /var/log/mysql
	mode1="master"
	mode2="slave"
	num=$(cat /etc/hostname | sed 's/[^0-9]//g')
	hostname=$(cat /etc/hostname |sed 's/[0-9]//g')
	if [ "$hostname" == "$mode1" ];then
        	echo "log-bin=/var/log/mysql/bin.log">>/etc/my.cnf
        	echo "server-id=$num">>/etc/my.cnf
	elif [ "$hostname" == "$mode2" ];then
        	cat >> /etc/my.cnf <<-EOF
		master-info-repository=table 
		relay-log-info-repository=table
		EOF
        	echo "server-id=$[100+$num]">>/etc/my.cnf
	fi
	systemctl restart mysqld
