#!/bin/bash

red_col="\033[31m"
green_col="\033[32m"
reset_col="\033[0m"
#------------------------------------------------------------------1---------------------------------------------------------
ping_ip(){
read -p "Please enter an IP address:" ipd
ping -c2 $ipd >/dev/null 2>&1
if [ $? -eq 0 ];then
	echo -e "${green_col}The network is normal${reset_col}"
else
	echo -e "${red_col}Network unreachable!!${reset_col}"
fi
}
#ping_ip
#------------------------------------------------------------------2----------------------------------------------------------
judge_user(){
read -p "Please enter a user name:" user
id $user >/dev/null 2>&1
if [ $? -eq 0 ];then
        echo -e "${green_col}The user exists.${reset_col}"
else
        echo -e "${red_col}The user does not exist!!${reset_col}"
fi
}
#judge_user
#------------------------------------------------------------------3-----------------------------------------------------------
judge_version(){
main=`uname -r | awk -F'.' '{print $1}' $version`
minor=`uname -r | awk -F'.' '{print $2}' $version`
if [ "$main" -eq 3 ] && [ "$minor" -ge 10 ];then
	echo -e "${green_col}The main version is $main
The minor version is $minor${reset_col}"
else
	echo -e "${red_col}The main version is not 3${reset_col}"
fi
}
#judge_version
#------------------------------------------------------------------4------------------------------------------------------------
judge_vsftpd(){
package=`rpm -qa |grep vsftpd |wc -l`
if [ "$package" -eq 0 ];then
	echo -e "${red_col}Vsftpd not installed, installing${reset_col}"
	sleep 2
	yum -y install vsftpd
else
	echo -e "${green_col}Vsftpd is already installed.${reset_col}"
	exit
fi
}
#judge_vsftpd
#------------------------------------------------------------------5------------------------------------------------------------
judge_httpd(){
service=`ps -ef |grep httpd|grep -v grep|wc -l`
if [ "$service" -ne 0 ];then
	echo -e "${green_col}The httpd service is running.${reset_col}"
else
	echo -e "${red_col}The httpd service is not running.${reset_col}"
fi
}
#judge_httpd
#------------------------------------------------------------------6-------------------------------------------------------------
judge_vsftpd_server(){
address=`ss -antpl|grep vsftpd|awk '{print $4}'`
port=`ss -antpl|grep vsftpd|awk '{print $4}'|awk -F':' '{print $4}'`
pid=`ps -ef |grep vsftpd|awk NR==1'{print $2}'`
systemctl status vsftpd &>/dev/null
if [ $? -eq 0 ];then
	echo "Vsftpd server started."
	echo "The address monitored by vsftpd is: $address"
	echo "The ports monitored by vsftpd are: $port"
	echo "The process PID of vsftpd is: $pid"
else
	echo "Vsftpd server not started !"
fi
}
#judge_vsftpd_server
#------------------------------------------------------------------7------------------------------------------------------------
warning(){
rpm -qa |grep mailx &>/dev/null
if [[ $? -ne 0 ]];then
    yum -y install mailx &>/dev/null
fi

id alice &>/dev/null
if [[ $? -ne 0 ]];then
    useradd alice &>/dev/null
fi
root_partition=`df -Th|awk NR==2'{print $(NF-1)}'|awk -F'%' '{print $1}'|awk -F'.' '{print $1}'`
mem=`free -m |awk NR==2'{print $3/$2*100}'|awk -F'.' '{print $1}'`
if [ "$root_partition" -gt 5 ];then
        echo "More than 80% of the used space of the root partition!" | mail -s "More than 80% of the used space of the root partition" alice
fi
if [ "$mem" -gt 5 ];then
        echo "Memory used space is greater than 80%!" | mail -s "Memory used space is greater than 80%!" alice
fi
}
#warning
#------------------------------------------------------------------8--------------------------------------------------------------
#warning
judge_number(){
read -p "Please enter a number:" number
expr $number + 1 >/dev/null 2>&1
if [ $? -ne 0 ];then
       	echo " $number is not number" 
else
	echo "$number is a  number"
fi
}
judge_number
#----------------------------------------------------------------------------------------------------------------------------------
