#!/bin/env bash
#v1.0
for name in $(cat $PWD/hostname.txt)
do
	/usr/bin/expect<<-EOF
	spawn ssh-copy-id $name
	expect {
		"yes/no" {send "yes\r";exp_continue}
		}
	expect eof
	EOF
done

ssh root@master1 "rpm -q vsftpd || yum -y install vsftpd; systemctl start vsftpd; systemctl enable vsftpd; mkdir -p /var/ftp/mysql_back; echo \"grant replication slave, replication client on *.* to 'rep'@'192.168.100.%' identified by 'My123@com';\" | mysql -p\"My5719@passwd\"; [ -d /backup ] || mkdir -p /backup;rm -rf /var/ftp/mysql_back/*; mysqldump -p\"My5719@passwd\" --all-databases --single-transaction --master-data=1 --flush-logs | tee /backup/$(date +%F-%H)-mysql-all.sql > /var/ftp/mysql_back/$(date +%F-%H)-mysql-all.sql"

m1binlog=$(ssh root@master1 "sed -n '22p' /var/ftp/mysql_back/*-mysql-all.sql | cut -d \' -f 2")
m1pos=$(ssh root@master1 "sed -n '22p' /var/ftp/mysql_back/*-mysql-all.sql | cut -d = -f 3 | sed 's/\;//g'")

ssh root@master2 "[ -d /backup ] || mkdir -p /backup && rm -rf /backup/*; wget -P /backup/ ftp://master1/mysql_back/*-mysql-all.sql; mysql -p\"My5719@passwd\" < /backup/*-mysql-all.sql; systemctl restart mysqld"

m2binlog=$(ssh root@master2 "echo \"show master status\G\"| mysql -p\"My5719@passwd\" | sed -n '2p'| cut -d ':' -f 2 | sed s/\ //g")
m2pos=$(ssh root@master2 "echo \"show master status\G\" |  mysql -p\"My5719@passwd\" | sed -n 3p | cut -d ':' -f 2 | sed s/\ //g")

ssh root@master1 "echo \"change master to master_host='master2', master_user='rep',master_port=3306,master_password='My123@com',master_log_file='$m2binlog',master_log_pos=$m2pos; start slave;\" | mysql -p\"My5719@passwd\""

ssh root@master2 "echo \"change master to master_host='master1', master_user='rep',master_port=3306,master_password='My123@com',master_log_file='$m1binlog',master_log_pos=$m1pos; start slave;\" | mysql -p\"My5719@passwd\""

for hostname in {slave1,slave2,slave3}
do	
	ssh root@$hostname "[ -d /backup ] || mkdir -p /backup && rm -rf /backup/*; wget -P /backup/ ftp://master1/mysql_back/*-mysql-all.sql; mysql -p\"My5719@passwd\" < /backup/*-mysql-all.sql; systemctl restart mysqld; echo \"change master to master_host='master1', master_user='rep',master_port=3306,master_password='My123@com',master_log_file='$m1binlog',master_log_pos=$m1pos for channel 'master1-channel';\" | mysql  -p\"My5719@passwd\"; echo \"change master to master_host='master2', master_user='rep',master_port=3306,master_password='My123@com',master_log_file='$m2binlog',master_log_pos=$m2pos for channel 'master2-channel';\" | mysql  -p\"My5719@passwd\""

done
