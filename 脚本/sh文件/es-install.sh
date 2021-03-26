#!/usr/bin/env bash
#filename es-install.sh 
#变量
red='\033[31m'
green='\033[32m'
end='\033[0m'

#判断
judge(){
	if [ $? -ne 0 ];then
		echo -e "$red Command execution failed...$end"
	fi
} 

#关闭防火墙和SELINUX
stop_firewalld(){
	systemctl stop firewalld && systemctl disable firewalld &>/dev/null
	setenforce 0 &>/dev/null
	sed -i '/^SELINUX=/c SELINUX=diabled' /etc/selinux/config
        echo -e "$green Firewall and SELinux shut down successfully $end"
}

#测试网络连通性
ping_network(){
	ping -c1 www.baidu.com &>/dev/null
	if [ $? -eq 0 ];then
		echo -e "$green The network is normal, please continue... $end"
	else
		echo -e "$red Network unreachable, command terminated$end"
		exit
	fi
}

#更新yum源
update_yum_repo(){
	rm -rf /etc/yum.repos.d/*
	curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo &>/dev/null
	yum clean all &>/dev/null && yum makecache &>/dev/null
	judge
        echo -e "$green Yum source updated successfully$end"
}
#安装常用软件包
software(){
	yum -y install wget vim expect &>/dev/null
        echo -e "$green Package installed successfully$end"
}

#本地解析
Local_resolution(){
read -p "Please enter the IP address of the first server: " ip1
read -p "Please enter the IP address of the second  server: " ip2
cat >>/etc/hosts <<eof
$ip1 es-1
$ip2 es-2
eof
echo -e "$green Local parsing successful$end"
}
#免密登陆
Secret_free_landing(){
rm -rf /root/.ssh/*
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
for k in es-2
do
expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$k
        expect {
                \"*yes/no*\" {send \"yes\n\"; exp_continue}
                \"*password*\" {send \"1026\n\"; exp_continue}
                \"*Password*\" {send \"1026\n\";}
        } "
done
echo -e "$green Secret free login successfully established$end"

}


#下载包
es-install(){
#wget http://www.xingdiancloud.com/elasticsearch-6.5.4.tar.gz 
#wget http://www.xingdiancloud.com/jdk-8u191-linux-x64.tar.gz 

#es-1
tar -xf jdk-8u191-linux-x64.tar.gz -C /usr/local/ &>/dev/null 
mv /usr/local/jdk1.8.0_191 /usr/local/java
cat >>/etc/profile <<eof
JAVA_HOME=/usr/local/java
PATH=$JAVA_HOME/bin:$PATH
export JAVA_HOME PATH
eof
source /etc/profile
useradd elsearch
echo "1026" | passwd --stdin "elsearch"  &>/dev/null
tar zxvf elasticsearch-6.5.4.tar.gz -C /usr/local/
cat >> /usr/local/elasticsearch-6.5.4/config/elasticsearch.yml <<eof
cluster.name: bjbpe01-elk
node.name: elk01
node.master: true
node.data: true
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
bootstrap.memory_lock: false
bootstrap.system_call_filter: false
network.host: 0.0.0.0
http.port: 9200
discovery.zen.ping.unicast.hosts: ["es-2"]
discovery.zen.ping_timeout: 150s
discovery.zen.fd.ping_retries: 10
client.transport.ping_timeout: 60s
http.cors.enabled: true
http.cors.allow-origin: "*"
eof

cat >> /usr/local/elasticsearch-6.5.4/config/elasticsearch-1.yml <<eof
cluster.name: bjbpe01-elk
node.name: elk02
node.master: true
node.data: true
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
bootstrap.memory_lock: false
bootstrap.system_call_filter: false
network.host: 0.0.0.0
http.port: 9200
discovery.zen.ping.unicast.hosts: ["es-1"]
discovery.zen.ping_timeout: 150s
discovery.zen.fd.ping_retries: 10
client.transport.ping_timeout: 60s
http.cors.enabled: true
http.cors.allow-origin: "*"
eof

#sed -i 's/-Xms1g/-Xms4g/' /usr/local/elasticsearch-6.5.4/config/jvm.options
#sed -i 's/-Xmx1g/-Xmx4g/' /usr/local/elasticsearch-6.5.4/config/jvm.options
mkdir -p /data/elasticsearch/{data,logs}
chown -R elsearch:elsearch /data/elasticsearch
chown -R elsearch:elsearch /usr/local/elasticsearch-6.5.4
cat >> /etc/security/limits.conf <<eof
*       soft     nofile          65536
*       hard     nofile          131072
*       soft     nproc           2048
*       hard     nproc           4096
eof
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p &>/dev/null
su - elsearch -c "cd /usr/local/elasticsearch-6.5.4 && nohup bin/elasticsearch &" 
#es-2
for e in es-2
do
        scp /etc/hosts root@$e:/etc/hosts
	scp jdk-8u191-linux-x64.tar.gz elasticsearch-6.5.4.tar.gz root@$e:/root
	ssh $e tar -xf jdk-8u191-linux-x64.tar.gz -C /usr/local/ 
        ssh $e mv /usr/local/jdk1.8.0_191 /usr/local/java
	scp /etc/profile root@$e:/etc/profile
	ssh $e useradd elsearch &>/dev/null && echo "123" | passwd --stdin "elsearch" >/dev/null
	ssh $e tar zxvf elasticsearch-6.5.4.tar.gz -C /usr/local/
	scp /usr/local/elasticsearch-6.5.4/config/elasticsearch-1.yml root@$e:/usr/local/elasticsearch-6.5.4/config/elasticsearch.yml
	ssh $e mkdir -p /data/elasticsearch/{data,logs} 
        ssh $e chown -R elsearch:elsearch /data/elasticsearch 
        ssh $e chown -R elsearch:elsearch /usr/local/elasticsearch-6.5.4
	scp /etc/security/limits.conf root@$e:/etc/security/limits.conf
	ssh $e echo "vm.max_map_count=262144" >> /etc/sysctl.conf 
        ssh $e sysctl -p &>/dev/null 
        ssh $e su - elsearch -c "cd /usr/local/elasticsearch-6.5.4 && nohup bin/elasticsearch &"
done
}

#            stop_firewalld
#            ping_network
#    	    update_yum_repo
#    	    software
    	    Local_resolution
    	    Secret_free_landing
    	    es-install

