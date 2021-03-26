#!/usr/bin/bash
#==========================
#virtual machine macmanager
#v1.0 by hexiang 2017-08-30
#==========================

red=\\e[31m
blue=\\e[34m
green=\\e[32m
end=\\e[0m
rpm -q expect &>/dev/null
if [ $? -ne 0 ]; then
	yum -y install expect &>/dev/null
fi
#菜单函数
menu(){
	cat <<-EOF
	==============================
	||  1. 开启所有虚机         ||
	||  2. 开启并登录一个虚机   ||
	||  3. 登录一个虚机         ||
	||  4. 关闭一个虚机         ||
	||  5. 关闭所有虚机         ||
	||  6. 列出所有虚机的状态   ||
	||  7. 列出主菜单           ||
	||  q. 退出                 ||
	==============================
	EOF
}
#登录函数
login_function(){
	unset mac
	unset ip
	mac=`virsh dumpxml "centos7u3-$1" | grep "mac address"| cut -b 21-37`
	ip=`arp -a| grep "$mac"| cut -b 4-18`
	expect expect.sh $ip
}

#循环函数
for_start(){
	unset i
	for i in {1..5}
	do	
		virsh start centos7u3-$i &>/dev/null
		echo -e "${green}centos7u3-$i start...${end}"
	done
	sleep 10
}
for_stop(){
	unset i
	for i in {1..5}
	do
		virsh shutdown centos7u3-$i &>/dev/null
		echo -e "${green}centos7u3-$i stop...${end}"
	done 
	sleep 2
}

#启动函数
start_function(){
	virsh start centos7u3-$1 &>/dev/null
	echo -e "${green}centos7u3-$1 start...${end}"
	sleep 18	
}

#关闭函数
stop_function(){
	virsh stop centos7u3-$1 &>/dev/null
	echo -e "${green}centos7u3-$1 stop...${end}"
	sleep 2		
}
#返回主菜单函数
return(){
	if [ "$1" == "n" ]; then
		clear
		menu
		continue
	fi

}

#主循环
menu
while true
do
	echo -ne "${blue}Please enter a order[7 for list menu]: ${end}" 
	read num
	case "$num" in
	1)
		for_start
		;;
	2)   	
		echo -ne "${blue}You want to start and login a machine[1-5]("n":return menu): ${end}"
		read num1
		return "$num1"
		start_function "$num1"
		login_function "$num1"
		break
		;;
	3)
		echo -ne "${blue}You want to login a machine[1-5]("n":return menu): ${end}"
		read num2
		return "$num2"
		login_function "$num2"
		break
		;;
	4)
		echo -ne "${blue}You want to stop a machine[1-5]("n":return menu): ${end}"
		read num3
		return "$num3"
		stop_function "$num3"
		;;
	5)
		for_stop
		;;
	6)	
		clear
		virsh list --all
		;;
	7)	
		clear
		menu
		;;
	"q")
		exit
		;;
	"")
		;;
	*)
		echo -e "${red}There is no such option!${end}"
		;;
	esac
done
