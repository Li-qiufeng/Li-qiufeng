#!/bin/bash
#disk_use cpu memory 
MAIL=6923114@qq.com
ip=10.18.42.78
disk_use(){
	use=`df -h |awk '{if(int($5)>=1) print $6}'`
	if [[ ${#use} -ge 80 ]];then
	echo "

        ip: $ip
	
        Problem: disk use more than 80:
 $use

    " | mail -s "Disk Monitor" $MAIL
	fi
}
mem_use(){
	TOTAL=`free -m |awk '/Mem/{print $2}'`	
	FREE=`free -m |awk '/Mem/{print $3}'`
}
disk_use
