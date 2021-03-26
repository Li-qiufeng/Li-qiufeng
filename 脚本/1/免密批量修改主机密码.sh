#!/usr/bin/bash
#file: second_week.sh-01

#1.使用case实现成绩优良差的判断
judge_score(){
read -p "Please enter your score:" score
case $score in
[0-5][0-9])
	echo "Failing in grades ！！！"
	;;
[6-8][0-9])
	echo "Good results, continue to work hard."
	;;
9[0-9]|100)
	echo "Good grades. Great."
	;;
esac
}

#2.创建20个用户
create_user(){
read -p "Please enter user prefix: " user
read -p "Please enter user initial password: " pd
for i in {1..20}
do
	useradd $user$i
	echo "Create user $user$i successfully"
	echo "$user$i:$pd" | chpasswd
	echo "Initial password changed successfully."

done
}

#3.ping测试指定网段的主机
ping_host(){
read -p "Please enter the network segment to test: " nt
for i in {10..20}
do
	ping -c2 $nt$i &>/dev/null
	if [ $? -eq 0 ];then
		echo "$nt$i is up ." >>/tmp/host_up.txt
	else
		echo "$nt$i is Down !" >>/tmp/host_down.txt	
	fi
done
}
#ping_host
#5.使用for实现批量主机root密码的修改
Password_modification(){
#安装必要软件包
rpm -qa | grep expect >/dev/null 2>&1
if [ $? -ne 0 ];then
	yum -y install expect &>/dev/null
        echo "expect Installation successful ."
fi
#实现免密登陆
rm -rf /root/.ssh/*
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa 
for k in `cat ip.txt` 
do
{
	expect -c "
	spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$k
	        expect {
	                \"*yes/no*\" {send \"yes\n\"; exp_continue}
	                \"*password*\" {send \"1026\n\"; exp_continue}
	                \"*Password*\" {send \"1026\n\";}
	        } "
}
done
#批量主机root密码的修改
read -p "Please enter a New Password: " pd
for ip in `cat ip.txt`
do
	{
		ping -c1 -W1 $ip &>/dev/null
		if [ $? -eq 0 ];then
			ssh $ip "echo $pd|passwd --stdin root"
			if [ $? -eq 0 ];then
				echo "$ip is ok ." >>ok_`date +%F`.txt
			else
				echo "$ip is fail ." >>fail_`date +%F`.txt
			fi
		else
				echo "$ip">>fail_`date+%F`.txt
		fi
	}
 
 
done
 
}
Password_modification

