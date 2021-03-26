#!/bin/bash
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
$ip1 ka-1
$ip2 ka-2
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

for l in ka-2
do
        scp /etc/hosts root@$l:/etc/hosts &>/dev/null
done
#kafka-1
wget http://www.xingdiancloud.com/kafka_2.11-2.1.0.tgz
wget http://www.xingdiancloud.com/jdk-8u191-linux-x64.tar.gz
tar xf jdk-8u191-linux-x64.tar.gz -C /usr/local
tar xf kafka_2.11-2.1.0.tgz -C /usr/local
mv /usr/local/jdk1.8.0_191 /usr/local/java
mv /usr/local/kafka_2.11-2.1.0 /usr/local/kafka

cat >> /etc/profile <<eof
JAVA_HOME=/usr/local/java
PATH=$JAVA_HOME/bin:$PATH
export JAVA_HOME PATH
eof
source /etc/profile
sed -i 's/^[^#]/#&/' /usr/local/kafka/config/zookeeper.properties
cat >> /usr/local/kafka/config/zookeeper.properties <<eof
dataDir=data/zookeeper/data
dataLogDir=data/zookeeper/logs
clientPort=2181 
tickTime=2000 
initLimit=20 
syncLimit=10 
server.1=$ip1:2888:3888
server.2=$ip2:2888:3888
eof
mkdir -p /data/zookeeper/{data,logs} 
echo 1 > /data/zookeeper/data/myid
sed -i 's/^[^#]/#&/' /usr/local/kafka/config/server.properties
cat >> /usr/local/kafka/config/server.properties <<eof
broker.id=1
listeners=PLAINTEXT://$ip1:9092
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/opt/data/kafka/logs
num.partitions=6
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=2
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=536870912
log.retention.check.interval.ms=300000
zookeeper.connect=$ip1:2181,$ip2:2181
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
eof
cat >> /usr/local/kafka/config/server.properties1 <<eof
broker.id=2
listeners=PLAINTEXT://$ip2:9092
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/opt/data/kafka/logs
num.partitions=6
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=2
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=536870912
log.retention.check.interval.ms=300000
zookeeper.connect=$ip1:2181,$ip2:2181
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
eof
mkdir -p /data/kafka/logs

#kafka-2
for i in ka-2
do
	scp jdk-8u191-linux-x64.tar.gz root@$i:/root
	scp kafka_2.11-2.1.0.tgz root@$i:/root
	ssh root@$i "mv /usr/local/jdk1.8.0_191 /usr/local/java"
	ssh root@$i "mv /usr/local/kafka_2.11-2.1.0 /usr/local/kafka"
	scp /etc/profile root@$i:/etc/profile
	ssh root@$i "source /etc/profile"
	scp /usr/local/kafka/config/zookeeper.properties root@$i:/usr/local/kafka/config/zookeeper.properties
	ssh root@$i "mkdir -p /data/zookeeper/{data,logs}"
	ssh root@$i "echo 2 > /data/zookeeper/data/myid"
	scp /usr/local/kafka/config/server.properties1 root@$i:/usr/local/kafka/config/server.properties
	ssh root@$i "mkdir -p /data/kafka/logs"
done


#启动
(cd /usr/local/kafka && nohup bin/zookeeper-server-start.sh config/zookeeper.properties &)
sleep 20
(cd /usr/local/kafka && nohup bin/kafka-server-start.sh config/server.properties &)

for u in ka-2
do
	ssh root@$u "(cd /usr/local/kafka && nohup bin/zookeeper-server-start.sh config/zookeeper.properties &)"
	ssh root@$U "(sleep 20 && cd /usr/local/kafka && nohup bin/kafka-server-start.sh config/server.properties &)"
done









