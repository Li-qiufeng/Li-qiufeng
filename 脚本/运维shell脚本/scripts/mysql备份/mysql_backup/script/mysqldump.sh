#!/bin/bash

PATH=$PATH:$HOME/bin:/usr/local/mysql/bin
LD_LIBRARY_PATH=dir:$LD_LIBRARY_PATH:/usr/local/mysql/lib
export LD_LIBRARY_PATH

bak_host="127.0.0.1"
bak_port="3306 3307"
bak_user="dba"
bak_pass="hfQ4SmrT538Nm7Ls"
bak_time=`date '+%Y%m%d%H%M'`
mysql_bin="/usr/local/mysql/bin/mysql"
source_dir=/dbbk1/mysql
rmpath=$source_dir

full(){
/usr/local/mysql/bin/mysqldump -u${bak_user} -p${bak_pass} -h ${bak_host} -P${2} --default-character-set=utf8mb4  --opt  --events --routines --triggers --add-drop-database=FALSE  --add-drop-table=TRUE --single-transaction  --log-error=${source_dir}/${2}/${1}.dump.sql.${bak_time}.err  --databases ${1} > ${source_dir}/${2}/${1}.dump.sql.${bak_time} 2>${source_dir}/${2}/${1}.dump.sql.${bak_time}.log
}

for port in ${bak_port}
	do
	mkdir -p $source_dir/${port}
	find $rmpath/${port} -name "*dump*" -mtime +30 -exec rm -rf {} \;
	$mysql_bin -u$bak_user -h127.0.0.1 -P$port -p$bak_pass -e "stop GROUP_REPLICATION;"
	$mysql_bin -u$bak_user -h127.0.0.1 -P$port -p$bak_pass -e "SET GLOBAL transaction_write_set_extraction=OFF;"
	/bin/echo "show databases" |$mysql_bin -u${bak_user} -p${bak_pass} -h ${bak_host} -P${port} -N|grep -v "\bperformance_schema\b"|grep -v "\btest\b"|grep -v "\bmysql\b"|grep -v "\binformation_schema\b"|grep -v "\binformation_schema\b"|grep -v "\bsys\b"|awk -F " " {'print $1'}|
	while read db_name
	   do
	                full ${db_name} ${port}
			echo $?
			echo ${port}
	   done
	$mysql_bin -u$bak_user -h127.0.0.1 -P$port -p$bak_pass -e "SET GLOBAL transaction_write_set_extraction=XXHASH64;"
	$mysql_bin -u$bak_user -h127.0.0.1 -P$port -p$bak_pass -e "start GROUP_REPLICATION;"
	done
