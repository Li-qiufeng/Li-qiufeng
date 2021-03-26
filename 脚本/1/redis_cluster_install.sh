#!/bin/bash
#file redis_cluster_install.sh

#判断
judge(){
        if [ $? -ne 0 ];then
                echo -e "Command execution failed..."
        fi
}

#本地解析
Local_resolution(){
read -p "Please enter the IP address of the first server: " ip1
read -p "Please enter the IP address of the second server: " ip2
read -p "Please enter the IP address of the third server: " ip3
cat >>/etc/hosts <<eof
$ip1 redis-1
$ip2 redis-2
$ip3 redis-3
eof
echo  "Local parsing successful."
}
Local_resolution

#免密登陆
Secret_free(){
yum -y install expect
rm -rf /root/.ssh/*
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
for k in redis-2 redis-3
do
expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$k
        expect {
                \"*yes/no*\" {send \"yes\n\"; exp_continue}
                \"*password*\" {send \"1026\n\"; exp_continue}
                \"*Password*\" {send \"1026\n\";}
        } "
done
judge
}
Secret_free

#redis-1
Modify_system(){
cat >> /etc/security/limits.conf << EOF
* soft nofile 102400
* hard nofile 102400
EOF
(echo "net.core.somaxconn = 32767" >> /etc/sysctl.conf && sysctl -p && sysctl -w net.core.somaxconn=32767)
(echo "vm.overcommit_memory=1" >> /etc/sysctl.conf && sysctl -p)
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.local
chmod +x /etc/rc.local
judge
}
Modify_system


for l in redis-2 redis-3
do
        scp /etc/hosts root@$l:/etc/hosts &>/dev/null
        scp /etc/security/limits.conf root@$l:/etc/security/limits.conf &>/dev/null
	ssh root@$l "(echo "net.core.somaxconn = 32767" >> /etc/sysctl.conf && sysctl -p &>/dev/null)"
	ssh root@$l "sysctl -w net.core.somaxconn=32767 &>/dev/null"
	ssh root@$l "(echo "vm.overcommit_memory=1" >> /etc/sysctl.conf && sysctl -p &>/dev/null)"
	ssh root@$l "(echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.local && chmod +x /etc/rc.local)"
done

#安装redis并配置redis-cluster
yum -y install gcc glibc glibc-kernheaders  glibc-common glibc-devel make
yum -y install centos-release-scl
yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
(scl enable devtoolset-9 bash && echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile && cd /usr/local/src/)
wget http://download.redis.io/releases/redis-6.0.5.tar.gz
tar xf redis-6.0.5.tar.gz 
(cd redis-6.0.5 && make && make install PREFIX=/usr/local/redis-cluster)
mkdir -p /redis/{6001,6002}/{conf,data,log}
(cd /redis/6001/conf/)
cat >> redis.conf << EOF
bind 0.0.0.0
protected-mode no
port 6001
dir /redis/6001/data
cluster-enabled yes
cluster-config-file /redis/6001/conf/nodes.conf
cluster-node-timeout 5000
appendonly yes
daemonize yes
\#requirepass redis
pidfile /redis/6001/redis.pid
logfile /redis/6001/log/redis.log
EOF
sed 's/6001/6002/g' redis.conf > /redis/6002/conf/redis.conf

for o in redis-2 redis-3
do
	ssh root@$o "yum -y install gcc glibc glibc-kernheaders  glibc-common glibc-devel make "
	ssh root@$o "yum -y install centos-release-scl "
	ssh root@$o "yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils "
	ssh root@$o "scl enable devtoolset-9 bash"
	ssh root@$o "echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile"
	ssh root@$o "cd /usr/local/src/ && wget http://download.redis.io/releases/redis-6.0.5.tar.gz "
	ssh root@$o "tar xf redis-6.0.5.tar.gz && cd redis-6.0.5 && make  && make install PREFIX=/usr/local/redis-cluster &>/dev/null"
	ssh root@$o "mkdir -p /redis/{6001,6002}/{conf,data,log}"
	scp /redis/6001/conf/redis.conf  root@$o:/redis/6001/conf/redis.conf
	scp /redis/6002/conf/redis.conf  root@$o:/redis/6002/conf/redis.conf
done

cat >/usr/local/redis-cluster/start-redis-cluster.sh<<-EOF
REDIS_HOME=/usr/local/redis-cluster
REDIS_CONF=/redis
\$REDIS_HOME/bin/redis-server \$REDIS_CONF/6001/conf/redis.conf
\$REDIS_HOME/bin/redis-server \$REDIS_CONF/6002/conf/redis.conf
EOF

(cd /usr/local/redis-cluster/ && chmod +x start-redis-cluster.sh && bash start-redis-cluster.sh )

