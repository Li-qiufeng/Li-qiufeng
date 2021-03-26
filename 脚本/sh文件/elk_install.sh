#!/bin/bash
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"
es=elasticsearch-6.5.4.tar.gz
jdk=jdk-8u191-linux-x64.tar.gz
ka=kafka_2.11-2.1.0.tgz
ki=kibana-6.5.4-linux-x86_64.tar.gz
he=master.zip
node=node-v4.4.7-linux-x64.tar.gz
ph=phantomjs-2.1.1-linux-x86_64.tar.bz2

panduan(){
	if [ $? -ne 0 ];then
		echo -e "${blue_col}Execution error, terminating scrip.......${reset_col}"
		exit
	fi
}

stop_firewalld(){
	systemctl stop firewalld && systemctl disable firewalld &>/dev/null
	setenforce 0 &>/dev/null
	sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
}

ping_baidu(){
	ping -c1 www.baidu.com >/dev/null 2>&1
	if [ $? -eq 0 ];then
		echo -e "${red_col}The network is normal. Please continue.........${reset_col}"
	else
		echo -e "${blue_col}Network exception, exiting........${reset_col}"
		exit
	fi

}

yum_repo(){
	rm -rf /etc/yum.repos.d/*
	curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all &>/dev/null && yum makecache >/dev/null 2>&1
	panduan	
}
soft_install(){
	yum -y install vim wget &>/dev/null
}
yum_repo
soft_install
read -p "Please enter the IP address of the first server:" ip1
read -p "Please enter the IP address of the second  server:" ip2

cat >> /etc/hosts <<eof
$ip1 es-1
$ip2 es-2
eof

yum -y install expect
rm -rf /root/.ssh/*
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
for k in es-2
do
expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$k
        expect {
                \"*yes/no*\" {send \"yes\n\"; exp_continue}
                \"*password*\" {send \"123\n\"; exp_continue}
                \"*Password*\" {send \"123\n\";}
        } "
done

for l in es-2
do
	scp /etc/hosts root@$l:/etc/hosts &>/dev/null
done

wget http://www.xingdiancloud.com/elasticsearch-6.5.4.tar.gz 
wget http://www.xingdiancloud.com/jdk-8u191-linux-x64.tar.gz

tar xf ./$es -C /usr/local
tar xf ./$jdk -C /usr/local
mv /usr/local/jdk1.8.0_191 /usr/local/java
mv /usr/local/elasticsearch-6.5.4 /usr/local/elasticsearch
cat >> /etc/profile <<eof
JAVA_HOME=/usr/local/java
PATH=\$JAVA_HOME/bin:\$PATH
export JAVA_HOME PATH
eof
source /etc/profile

useradd elsearch
echo "123" | passwd --stdin "elsearch"
read -p "Please enter the cluster name:" name1
read -p "Please enter the node-1 name:" name2
read -p "Please enter the node-2 name:" name3
cat  >>/usr/local/elasticsearch/config/elasticsearch.yml <<eof
cluster.name: $name1
node.name: $name2
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
cat  >>/usr/local/elasticsearch/config/elasticsearch1.yml <<eof
cluster.name: $name1
node.name: $name3
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

for w in es-2
do 
 	scp $jdk root@$w:/root
	scp $es root@$w:/root
	ssh root@$w "tar xf /root/$es -C /usr/local && tar xf /root/$jdk -C /usr/local"
	ssh root@$w "mv /usr/local/elasticsearch-6.5.4 /usr/local/elasticsearch && mv /usr/local/jdk1.8.0_191 /usr/local/java"
	scp /usr/local/elasticsearch/config/elasticsearch1.yml root@$w:/usr/local/elasticsearch/config/elasticsearch.yml 
	scp /etc/profile root@$w:/etc/profile
	ssh root@$w "source /etc/profile"

done

sed -i 's/-Xms1g/-Xms4g/' /usr/local/elasticsearch/config/jvm.options
sed -i 's/-Xmx1g/-Xmx4g/' /usr/local/elasticsearch/config/jvm.options
mkdir -p /data/elasticsearch/{data,logs}
chown -R elsearch:elsearch /data/elasticsearch
chown -R elsearch:elsearch /usr/local/elasticsearch
cat >> /etc/security/limits.conf <<eof
*       soft     nofile          65536
*       hard     nofile          131072
*       soft     nproc           2048
*       hard     nproc           4096
eof

echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p &>/dev/null
su - elsearch -c "cd /usr/local/elasticsearch && nohup bin/elasticsearch &" 
panduan

for u in es-2
do
	ssh root@$u "sed -i 's/-Xms1g/-Xms4g/' /usr/local/elasticsearch/config/jvm.options"
	ssh root@$u "sed -i 's/-Xmx1g/-Xmx4g/' /usr/local/elasticsearch/config/jvm.options"
	ssh root@$u "useradd elsearch"
	ssh root@$u "mkdir -p /data/elasticsearch/{data,logs}"
	ssh root@$u "chown -R elsearch:elsearch /data/elasticsearch && chown -R elsearch:elsearch /usr/local/elasticsearch"
	scp /etc/security/limits.conf root@$u:/etc/security/limits.conf
	ssh root@$u "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf && sysctl -p &>/dev/null"
	ssh root@$u "su - elsearch -c 'cd /usr/local/elasticsearch-6.5.4 && nohup bin/elasticsearch &'"
done

#install node
#es-1
wget http://www.xingdiancloud.com/$node
tar -zxf $node -C /usr/local
mv /usr/local/node-v4.4.7-linux-x64  /usr/local/node
cat >> /etc/profile <<eof
NODE_HOME=/usr/local/node
PATH=\$NODE_HOME/bin:\$PATH
export NODE_HOME PATH
eof
source /etc/profile

yum -y install unzip &>/dev/null
wget http://www.xingdiancloud.com/master.zip
unzip -d /usr/local master.zip &>/dev/null
(cd /usr/local/elasticsearch-head-master && npm install -g grunt-cli)
rm -rf /usr/local/elasticsearch-head-master/Gruntfile.js
curl -o /usr/local/elasticsearch-head-master/ http://www.xingdiancloud.com/Gruntfile.js
read -p "ip1:" ip3
read -p "ip2:" ip4 
sed -i "s/localhost/${ip3}/" /usr/local/elasticsearch-head-master/_site/app.js
yum -y install bzip2 &>/dev/null
wget http://www.xingdiancloud.com/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar -jxf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /tmp/
(cd /usr/local/elasticsearch-head-master/ && npm install && nohup grunt server &)

#es-2
for m in es-2
do
	scp $node root@$m:/root/
	ssh root@$m "tar -zxf $node -C /usr/local && mv /usr/local/node-v4.4.7-linux-x64  /usr/local/node"
        scp /etc/profile root@$m:/etc/profile
	ssh root@$m "source /etc/profile"
	scp $he root@$m:/root/
	ssh root@$m "unzip -d /usr/local master.zip & >/dev/null"
	ssh root@$m "(cd /usr/local/elasticsearch-head-master && npm install -g grunt-cli)"
	ssh root@$m "rm -rf /usr/local/elasticsearch-head-master/Gruntfile.js"
	ssh root@$m "curl -o /usr/local/elasticsearch-head-master/ http://www.xingdiancloud.com/Gruntfile.js"
	ssh root@$m "(sed -i "s/localhost/${ip3}/" /usr/local/elasticsearch-head-master/_site/app.js)"
	ssh root@$m "yum -y install bzip2 &>/dev/null"
	scp $ph root@$m:/root
	ssh root@$m "tar -jxf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /tmp/"
	ssh root@$m "(cd /usr/local/elasticsearch-head-master/ && npm install && nohup grunt server &)"
done
#kibana
wget http://www.xingdiancloud.com/kibana-6.5.4-linux-x86_64.tar.gz
tar zxf kibana-6.5.4-linux-x86_64.tar.gz -C /usr/local/
mv /usr/local/kibana-6.5.4-linux-x86_64/ /usr/local/kibana
cat >> /usr/local/kibana/config/kibana.yml <<eof
server.port: 5601
server.host: "$ip1"
elasticsearch.url: "http://$ip1:9200"
kibana.index: ".kibana"
eof
(cd /usr/local/kibana && nohup ./bin/kibana &)
