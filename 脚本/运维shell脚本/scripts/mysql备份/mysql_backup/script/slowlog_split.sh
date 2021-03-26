#!/bin/bash

source ~/.bash_profile
mkdir -p /home/mysql/cron/log

ps -ef | grep mysql | grep port | grep -v "grep"| awk -F"=" '{print $NF}' | sort > /home/mysql/cron/script/mysql_backup_port.txt
user=dba
passwd=hfQ4SmrT538Nm7Ls
htime=`date +'%Y%m%d%H'`

slowlog()
{
if [ $cnt -gt 0 ]; then
mysql -u$user -h127.0.0.1 -P$port -p$passwd -e "set global slow_query_log = 0"
cp -f $slowlog $slowlog.$htime &&  > $slowlog
mysql -u$user -h127.0.0.1 -P$port -p$passwd -e "set global slow_query_log = 1"
find $slowlog.* -mtime +30 -type f | xargs rm -f
fi
}

while read line
do
port=$line
slowlog=`mysql -u$user -h127.0.0.1 -P$port -p$passwd --column-names=FALSE -e "show variables like 'slow_query_log_file';"|awk '{print $2}'`
echo $slowlog
htime=`date +%Y%m%d%H`
declare -i cnt=`grep "# Query_time" $slowlog | wc -l`
slowlog $port $cnt $slowlog $htime
if [ $? -gt 0 ];then
errnum=2
INFO='Analysis slowlog errer'
else
errnum=1
INFO='Success'
fi
done</home/mysql/cron/script/mysql_backup_port.txt
