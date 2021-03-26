#!/usr/bin/env bash 
#write by blackmed
#xtrabackup
read -p "请输入mysql的root密码：" mima
time=`date +%a`
if [ "${time}" == "Mon" ];then
	mkdir /backup/full -p
	innobackupex --user=root --password=${mima} /backup/full/
elif [ "${time}" == "Tue" ];then
	cd /backup/full/;ls >/tmp/a.txt
	mkdir /backup/zeng
	file1=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/full/${file1} 

elif [ "${time}" == "Wed" ];then
	cd /backup/zeng;ls >/tmp/a.txt
	file2=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/zeng/${file2}
 
elif [ "${time}" == "Thu" ];then
	cd /backup/zeng;ls >/tmp/a.txt
	file3=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/zeng/${file3}

elif [ "${time}" == "Fri" ];then
	cd /backup/zeng;ls >/tmp/a.txt
	file4=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/zeng/${file4}

elif [ "${time}" == "Sat" ];then
	cd /backup/zeng;ls >/tmp/a.txt
	file5=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/zeng/${file5}

elif [ "${time}" == "Sun" ];then
	cd /backup/zeng;ls >/tmp/a.txt
	file6=`cat /tmp/a.txt | sed '/^$/!h;$!d;g'`
	innobackupex --user=root --password=${mima} --incremental /backup/zeng/ --incremental-basedir=/backup/zeng/${file6}
else 
	echo ${time}
fi
