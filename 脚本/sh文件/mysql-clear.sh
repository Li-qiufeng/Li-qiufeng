#!/usr/bin/env bash 
#write by blackmed
#mysql-clean
clean() {
	systemctl stop mysqld 
	if [ $? -eq 0 ];then
		rm -rf /var/lib/mysql/*
		echo ' ' > /var/log/mysqld.log
		cat /etc/my.cnf | grep validate >/dev/null
		if [ $? -eq 0 ];then
			sed -i '/validate_/c\#validate_password=off' /etc/my.cnf
			systemctl start mysqld
			sed -i '/\#validate_/cvalidate_password=off' /etc/my.cnf
			systemctl restart mysqld
			pass1=`grep password /var/log/mysqld.log  | grep root@localhost | awk -F ' ' '{print $NF}'`
                        mysqladmin -u root -p''${pass1}'' password '123'
			
		else 
			systemctl start mysqld
			echo "validate_password=off" >> /etc/my.cnf
			systemctl restart mysqld
			pass=`grep password /var/log/mysqld.log  | grep root@localhost | awk -F ' ' '{print $NF}'`
			mysqladmin -u root -p''${pass}'' password '123'

		fi
	else
		read -p "You don't install MySQL and install a new MySQL[q/y]!" num
		if [ "$num" == "q" ];then
			exit
			clear
		elif [ "$num" == "y" ];then
			mysql_install
		
		else
			exit 
			clear
		fi
	fi
	}
mysql_install() {
	 	scp  10.18.44.208:/root/Desktop/blackmed.cn/blackmed.cn/mysql/mysql_rpm/* /root/
		yum -y remove mariadb* >/dev/null
		userdel -r mysql
		rpm -ivh /root/*.rpm >/dev/null
		if [ $? -eq 0 ];then 
			echo "mysql is install Success！"
		else 
			echo "mysql is not install!"
		fi
}
read -p "Whether a single key is emptied mysql[y/n]:" p
	if [ "$p" == "y" ];then
		clean
		echo "Complete！"
	elif [ "$p" == "n" ];then
		exit
	else
		echo " There is a mistake in the input. Please reenter it！"


	fi
