#!/bin/bash
#by:qiufeng
#kubernetes scripts
# 此脚本在master节点执行

#网络检查
xingdian1() {
ping -c1 www.baidu.com >/dev/null 2>&1
if [ $? -ne 0 ];then
	echo "网络连接失败，不能继续执行kubernetes集群的安装...."
	exit
else
	echo "网络正常,继续执行中...."
fi
}

xingdian1
#关闭防火墙和selinux
xingdian2(){
setenforce 0 &>dev/null && systemctl stop firewalld && systemctl disable firewalld >/dev/null 2>&1
for q in node1 node2
do
	ssh root@$q setenforce 0 &>dev/null && systemctl stop firewalld && systemctl disable firewalld >/dev/null 2>&1	
done
}
#关闭交换分区
xingdian3(){
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
for w in node1 node2
do
	ssh root@$w swapoff -a
	ssh root@$w sed -i 's/.*swap.*/#&/' /etc/fstab
done
}
#创建域名解析
read -p "请输入master的ip地址:" master
read -p "请输入node1的ip地址:" node1
read -p "请输入node2的ip地址:" node2
cat >> /etc/hosts <<eof
$master master
$node1 node1
$node2 node2
eof
#测试
ping -c1 node1 >/dev/null 2>&1
if [ $? -ne 0 ];then
	echo "解析不成功,正在退出...."
	exit
else
	echo "解析成功,正在继续...."
fi

#在master节点分发秘钥,注意所有节点的密码为1234.com,如果不是记得修改
yum install -y expect >/dev/null 2>&1
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
for i in master node1 node2
do
expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i
        expect {
                \"*yes/no*\" {send \"yes\r\"; exp_continue}
                \"*password*\" {send \"123\r\"; exp_continue}
                \"*Password*\" {send \"123\r\";}
        } "
done 
if [ $? -ne 0 ];then
	echo "免密失败,正在退出....."
	exit
else
	echo "免密成功,正在继续..."
fi

#分发到所有节点
for a in node1 node2
do
	scp /etc/hosts $a:/etc/hosts
done

xingdian2
xingdian3
#开启内核ipv4转发需要加载br_netfilter模块(所有节点)
for k in node1 node2
do
	ssh root@$k modprobe br_netfilter &>/dev/null
	ssh root@$k modprobe ip_conntrack &>/dev/null
done
modprobe br_netfilter && modprobe ip_conntrack
if [ $? -ne 0 ];then
	echo "执行加载br_netfilter模块失败,正在进行退出......."
	exit
else
	echo "加载模块成功,正在继续执行~"
fi

#优化内核参数
cat >> /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
#vm.swappiness=0 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
#vm.overcommit_memory=1 不检查物理内存是否够用
#vm.panic_on_oom=0 开启 OOM
if [ $? -ne 0 ];then
	echo "内核优化文件没有创建成功,正在退出......"
	exit
else
	echo "内核优化文件创建成功,正在继续...."
fi
#分发到所有节点.注意:需要实现做好域名解析
for u in node1 node2
do
	scp /etc/sysctl.d/kubernetes.conf $u:/etc/sysctl.d/kubernetes.conf 
	ssh root@$u "sysctl -p /etc/sysctl.d/kubernetes.conf "
done

#所有节点安装ipvs(1.18版本)
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack &>/dev/null

yum install ipset -y &>/dev/null
yum install ipvsadm -y >/dev/null 2>&1
timedatectl set-timezone Asia/Shanghai
#将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0
#重启依赖于系统时间的服务
systemctl restart rsyslog 
systemctl restart crond

#docker安装
yum install -y yum-utils device-mapper-persistent-data lvm2 git &>/dev/null
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  &>/dev/null
yum install docker-ce -y  &>/dev/null
for y in node1 node2
do
	ssh root@$y yum install -y yum-utils device-mapper-persistent-data lvm2 git &>/dev/null
	ssh root@$y yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  &>/dev/null
	ssh root@$y yum install docker-ce -y  &>/dev/null
done
# 配置镜像加速
mkdir -p /etc/docker/
cat>/etc/docker/daemon.json<<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
      "https://fz5yth0r.mirror.aliyuncs.com",
      "https://dockerhub.mirrors.nwafu.edu.cn/",
      "https://mirror.ccs.tencentyun.com",
      "https://docker.mirrors.ustc.edu.cn/",
      "https://reg-mirror.qiniu.com",
      "https://registry.docker-cn.com"
  ],
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
for t in  node1 node2
do
	ssh root@$t mkdir /etc/docker
	scp /etc/docker/daemon.json $t:/etc/docker/daemon.json
	ssh root@$t systemctl start docker && systemctl enable docker &>/dev/null
done
systemctl start docker && systemctl enable docker &>/dev/null

echo "所有docker安装完成，并正常运行"

#kubernetes的kubeadm安装
#创建镜像
cat >> /etc/yum.repos.d/kubernetes.repo <<eof
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg 
eof
yum install -y kubelet kubeadm kubectl >/dev/null 2>&1 
cat >/etc/sysconfig/kubelet<<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1"
EOF
cat >> /kubeadm.sh <<eof
K8S_VERSION=v1.18.6
ETCD_VERSION=3.4.3-0
DASHBOARD_VERSION=v1.8.3
FLANNEL_VERSION=v0.10.0-amd64
DNS_VERSION=1.6.7
PAUSE_VERSION=3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:$ETCD_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:$PAUSE_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:$DNS_VERSION
docker pull quay.io/coreos/flannel:$FLANNEL_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:$K8S_VERSION k8s.gcr.io/kube-apiserver:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:$K8S_VERSION k8s.gcr.io/kube-controller-manager:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:$K8S_VERSION k8s.gcr.io/kube-scheduler:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:$K8S_VERSION k8s.gcr.io/kube-proxy:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:$ETCD_VERSION k8s.gcr.io/etcd:$ETCD_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:$PAUSE_VERSION k8s.gcr.io/pause:$PAUSE_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:$DNS_VERSION k8s.gcr.io/coredns:$DNS_VERSION
eof
bash /kubeadm.sh
for b in node1 node2
do
	scp /etc/yum.repos.d/kubernetes.repo $b:/etc/yum.repos.d/kubernetes.repo
	ssh root@$b yum install -y kubelet kubeadm kubectl >/dev/null 2>&1
	scp /etc/sysconfig/kubelet $b:/etc/sysconfig/kubelet
	scp /kubeadm.sh $b:/kubeadm.sh 
	ssh root@b bash /kubeadm.sh
done
