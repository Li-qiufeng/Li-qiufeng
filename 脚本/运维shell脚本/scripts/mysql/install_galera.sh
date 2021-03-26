#!/bin/env bash
#install galera 5.7.18
#
#name time
	sed -ri '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
	setenforce 0
	systemctl stop firewalld.serveice
	systemctl disable firewalld.service

	rpm -q wget
	if [ $? -ne 0 ]; then
		yum -y install wget >/dev/null
	fi
	wget ftp://192.168.100.1/galera.repo -P /etc/yum.repos.d/
	yum repolist

	yum -y install galera mysql-wsrep*
	systemctl start mysqld
	systemctl enable mysqld

	tempassword=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
	newpassword=My5719@passwd
	mysqladmin -uroot -p"$tempassword" password "$newpassword"
	
	mkdir /var/log/mysql
	chown -R mysql.mysql /var/log/mysql
	cat >> /etc/my.cnf <<-EOF
	log-bin=/var/log/mysql/bin.log
	server-id=
	binlog_format=row

	default_storage_engine=InnoDB
	innodb_file_per_table=1
	innodb_autoinc_lock_mode=2

	wsrep_on=on
	wsrep_provider=/usr/lib64/galera-3/libgalera_smm.so
	wsrep_cluster_name='galera'
	wsrep_cluster_address='gcomm://'
	wsrep_node_name='galera1'
	wsrep_node_address='192.168.100.'
	wsrep_sst_auth=user:My123@com
	wsrep_sst_method=rsync
	
	slow_query_log=1
	slow_query_log_file=/var/log/mysql/slow.log
	long_query_time=3
	EOF

	systemctl restart mysqld
	reboot

