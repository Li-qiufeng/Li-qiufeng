#!/bin/bash
source /etc/profile
source /home/mysql/.bash_profile

mysql_bin="/usr/local/mysql/bin/mysql"
NOW=`date '+%Y%m%d%H%M'`
source_dir=/dbbk1/xtrabackup
cron_path=/home/mysql/cron/script
log_path=/home/mysql/cron/log
LOCAL_HOST_NAME=`hostname`
local_ip=`cat /etc/hosts | grep -v 'vip'| grep -v 'priv'|grep ${LOCAL_HOST_NAME} | awk -F ' ' '{print $1}'`
innobkup="/usr/bin/innobackupex"
bakopt=" --stream=xbstream  --compress --compress-threads=4 --slave-info --parallel=4 --safe-slave-backup --safe-slave-backup-timeout=1800 --kill-long-queries-timeout=10 --kill-long-query-type=all "
user="dba"
passwd="hfQ4SmrT538Nm7Ls"
host="127.0.0.1"
bak_port=`ps -ef | grep mysql | grep port | grep -v "grep"| awk -F"=" '{print $NF}' | sort`
db_type="mysql"

if [ -d $cron_path ];then
        echo 1
else
        mkdir -p $cron_path
fi
if [ -d $log_path ];then
        echo 1
else
        mkdir -p $log_path
fi

# Full Backup
full()
{
cd ${6}
mkdir -p ${7}_chkpoint
$innobkup --defaults-file=${1} --user=${2} --password=${3} --host=${4} --port=${5} $bakopt --extra-lsndir=${6}/${7}_chkpoint $source_dir > ${6}/bak_compress_${7}.xbstream 2>> $log_path/monitor_xtrabackup_full.log
if [ $? == 0 ]
        then
        cd ${6}
        find ${6} -type d -mtime +15 |xargs -i rm -rf {}
        find ${6} -name "bak_compress*.xbstream" -mtime +15 |xargs -i rm -rf {}
        echo 1
else
        CONTENT="${7} ${local_ip} ${5} backup failed"
        #/usr/bin/curl -d "phones=$PHONES&content=$CONTENT""25" "http://10.130.32.21:8080/alarm/sendmessage" 
        echo $CONTENT
fi
}

for port in ${bak_port}
do
        bakpath=$source_dir/$port/bak_full
        cnf="/usr/local/mysql"${port}"/my.cnf"
        if [ -d $bakpath ];then
        echo 1
        else
        mkdir -p $bakpath
        fi
        full $cnf $user $passwd $host $port $bakpath $NOW 
done
