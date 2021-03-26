#!/bin/env bash
#install mysql 5.7.19
#
#name time
	sed -ri '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
	setenforce 0
	firewall-cmd --permanent --add-service=mysql
	firewall-cmd --reload 

	yum -y install https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
	yum repolist

	yum -y install mysql-community-server.x86_64
	systemctl start mysqld
	systemctl enable mysqld

	tempassword=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
	newpassword=My5719@passwd
	mysqladmin -uroot -p"$tempassword" password "$newpassword"
	
	mkdir /var/log/mysql
	chown -R mysql.mysql /var/log/mysql
	cat >> /etc/my.cnf <<-EOF
	log-bin=/var/log/mysql/bin.log
	server-id=100
	slow_query_log=1
	slow_query_log_file=/var/log/mysql/slow.log
	long_query_time=3
	EOF

	systemctl restart mysqld
	mysql -uroot -p"$newpassword"
	
