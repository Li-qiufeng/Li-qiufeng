#!/bin/bash
DATE=$(date +%F" "%H:%M)
IP=`ifconfig | awk -F' ' 'NR==2{print $2}'`
MAIL="liuchao07a@163.com"
if ! which vmstat &>/dev/null; then
    echo "vmstat command no found, Please install procps package." 
    exit 1
fi
US=$(vmstat |awk 'NR==3{print $13}')
SY=$(vmstat |awk 'NR==3{print $14}')
IDLE=$(vmstat |awk 'NR==3{print $15}')
WAIT=$(vmstat |awk 'NR==3{print $16}')
USE=$(($US+$SY))
if [ $USE -ge 50 ]; then
    echo "
    Date: $DATE
    Host: $IP
    Problem: CPU utilization $USE
    " | mail -s "CPU Monitor" $MAIL
fi