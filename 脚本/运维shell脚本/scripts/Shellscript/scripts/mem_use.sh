#!/usr/bin/bash
mem_used=`free -m |grep '^Mem:' |awk '{print $3}'`
mem_total=`free -m |grep '^Mem:' |awk '{print $2}'`
mem_percent=$((mem_used*100/mem_total))
war_file=/tmp/mem_war.txt
rm -rf $war_file

if [ $mem_percent -ge 80 ];then
	echo "`date +%F-%H` memory:${mem_percent}%" > $war_file
fi

if [ -f $war_file ];then
	mail -s "mem war..." alice < $war_file
	rm -rf $war_file
fi
