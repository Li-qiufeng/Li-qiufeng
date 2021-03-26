#!/usr/bin/bash
#filename three_week.sh
#主机信息每日巡检

System_check(){
	echo "############################ 系统检查 ############################"
	if [ -e /etc/sysconfig/i18n ];then
        	default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
	else
		default_LANG=$LANG
	fi
	export LANG='en_US.UTF-8'
	Release=$(cat /etc/redhat-release 2>/dev/null)  #发行版本
	Kernel=$(uname -r)                              #输出内核发行号
	OS=$(uname -o)                                  #输出操作系统名称
	Hostname=$(uname -n)                            #输出网络节点上的主机名
	Selinux=$(getenforce)                           #selinux状态
	Currtime=$(date +'%F %T')                       #时间
	LastReboot=$(who -b|awk '{print $3,$4}')        #上次系统启动时间
	uptime=$(uptime|awk -F'[ ,]' '{print $5}')      #正常运行时间
	echo " 操作系统：$OS"
	echo " 发行版本：$Release"
	echo "     内核：$Kernel"
	echo "   主机名：$Hostname"
	echo "  SELinux：$Selinux"
	echo "语言/编码：$LANG"
	echo " 当前时间：$Currtime"
	echo " 最后启动：$LastReboot"
	echo " 运行时间：$uptime"

}
System_check
