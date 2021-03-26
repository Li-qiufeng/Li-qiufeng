#!/usr/bin/env bash 
#mysql 编译安装 by blackmed
blackmed(){

	rpm -qa | grep mariadb
	if [ $? -eq 0 ];then
		rpm -e --nodeps >/dev/null
	fi
	rm -rf /etc/my* >/dev/null
	rm -rf /var/lib/mysql >/dev/null
	userdel -r mysql >/dev/null

	rpm -qa | grep cmake
	if [ $? -ne 0 ];then 
	yum -y install cmake ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make >/dev/null
	echo "========================================"
	echo "The success of the prophase environment."
	echo "========================================"
	fi
	
	useradd -r mysql -M -s /sbin/nologin
	

	mkdir /mysql
	wget  -O /mysql/mysql-5.7.20.tar.gz https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.20.tar.gz   >/dev/null
	tar xvf /mysql/mysql-5.7.20.tar.gz -C /mysql/
	cd /mysql/mysql-5.7.20
	
	cmake .  -DDOWNLOAD_BOOST=1 -DWITH_BOOST=boost_1_59_0/ -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DMYSQL_DATADIR=/usr/local/mysql/data -DINSTALL_MANDIR=/usr/share/man -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DEXTRA_CHARSETS=all -DDEFAULT_COLLATION=utf8_general_ci -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1
	

		make && make install
		echo "==========================="
		echo "mysql install successfully"
		echo "==========================="

	chown -R mysql.mysql /usr/local/mysql/
	local_mysql=/usr/local/mysql/bin
	${local_mysql}/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data 
	mima=`${local_mysql}/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data | awk '/localhost\:/{print $NF}' `
	touch /etc/my.cnf
	echo "[mysqld]" >> /etc/my.cnf
	echo "basedir=/usr/local/mysql" >> /etc/my.cnf
	echo "datadir=/usr/local/mysql/data" >> /etc/my.cnf

	sed -i '/PATH=/cPATH=$PATH:$HOME/bin:/usr/local/mysql/bin' ~/.bash_profile

	source ~/.bash_profile

	mysqld_safe --user=mysql &	
	mysqladmin -u root -p${mima} password 1
	echo "==============================================="
	echo "Initialization completion can be used normally."
	echo "==============================================="
	}
blackmed
