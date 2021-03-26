#!/usr/bin/bash
disk_use=`df -Th |grep '/$' |awk '{print $(NF-1)}' |awk -F"%" '{print $1}'`
mail_user=alice

if [ $disk_use -ge 8 ];then
	echo "`date +%F-%H` disk: ${disk_use}%" |mail -s "disk war..." $mail_user
fi
