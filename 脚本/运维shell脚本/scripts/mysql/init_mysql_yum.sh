#!/bin/env bash
#v1.0
systemctl stop mysqld
if [ $? -ne 0 ];then	
	echo 'mysql stop failure'
	exit
else
	rm -rf /var/lib/mysql/*
	>/var/log/mysqld.log
	rm -rf /var/log/mysql/*
	systemctl start mysqld
	if [ $? -eq 0 ];then
		tempassword=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
		newpassword=My5719@passwd
		mysqladmin -uroot -p"$tempassword" password "$newpassword" &>/dev/null
		echo "mysql initialization complete"
	else
		echo "mysql boot failure"
	fi
fi

