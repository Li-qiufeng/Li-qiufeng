#!/bin/bash
#################################################
#  --Info
#         Initialization CentOS 7.x script
#################################################
#   Auther: li1922857947@163.com
#   Changelog:
#   2020710   wanghui  initial create
#################################################

# Check if user is root
#
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to initialization OS."
    exit 1
fi

echo "+------------------------------------------------------------------------+"
echo "|       To initialization the system for security and performance        |"
echo "+------------------------------------------------------------------------+"

# Set host name
set_name()
{
read -p "Please enter the host name" hostnames
hostnamectl --static set-hostname $hostnames
}


# delete useless user and group
user_del()
{
  userdel -r adm
  userdel -r lp
  userdel -r games
  userdel -r ftp
  groupdel adm
  groupdel lp
  groupdel games
  groupdel video
  groupdel ftp
}

# update system & install pakeage
#system_update(){
#    nameserver=`grep nameserver /etc/resolv.conf | wc -l`
#    if [ $nameserver -ge 1 ];then
#    echo nameserver is exist.
#    else
#    echo add nameserver in /etc/resolv.conf
#    echo "nameserver 114.114.114.114" >>/etc/resolv.conf
#    fi
#
#    echo "*** Starting update system && install tools pakeage... ***"
#    yum install epel-release -y && yum -y update
#    yum clean all && yum makecache
#    yum -y install vim openssh-clients iftop iotop sysstat lsof telnet traceroute tree man net-tools dstat ntpdate git egrep
#    [ $? -eq 0 ] && echo "System upgrade && install pakeages complete."
#}


repo_update(){
     echo "*** Starting update repo && install tools pakeage... ***"
     cd /etc/yum.repos.d/ && rm -rf ./* && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && yum -y install wget && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
     yum clean all && rm -rf /var/cache/yum &&  yum makecache
     yum -y install vim openssh-clients iftop iotop sysstat lsof telnet traceroute tree man net-tools dstat ntpdate
     [ $? -eq 0 ] && echo "System upgrade && install pakeages complete."

}


# Set timezone synchronization
timezone_config()
{
    echo "Setting timezone..."
    /usr/bin/timedatectl | grep "Asia/Shanghai"
    if [ $? -eq 0 ];then
       echo "System timezone is Asia/Shanghai."
       else
       timedatectl set-local-rtc 0 && timedatectl set-timezone Asia/Shanghai
    fi
    # config chrony
    yum -y install chrony
    sed -i '$a 192.168.0.205 time.aniu.so' /etc/hosts
    sed -i 's/server 0.centos.pool.ntp.org iburst/server time.aniu.so iburst/g' /etc/chrony.conf
    systemctl start chronyd.service && systemctl enable chronyd.service
    [ $? -eq 0 ] && echo "Setting timezone && Sync network time complete."
}

# disable selinux
selinux_config()
{
       sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
       setenforce 0
       echo "Dsiable selinux complete."
}

# ulimit comfig
ulimit_config()
{
echo "Starting config ulimit..."
cat >> /etc/security/limits.conf <<EOF
* soft nproc 8192
* hard nproc 8192
* soft nofile 8192
* hard nofile 8192
EOF

ulimit -n 8192

[ $? -eq 0 ] && echo "Ulimit config complete!"

}

# sshd config
sshd_config(){
    echo "Starting config sshd..."
    sed -i '/^#Port/s/#Port 22/Port 54077/g' /etc/ssh/sshd_config
    sed -i '/^#UseDNS/s/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    sed -i '/^GSSAPIAuthentication/s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    #if you do not want to allow root login,please open below
    #sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    [ $? -eq 0 ] && echo "SSH config complete."
}

# firewalld config
disable_firewalld(){
   echo "Starting disable firewalld..."
   rpm -qa | grep firewalld >> /dev/null
   if [ $? -eq 0 ];then
      systemctl stop firewalld  && systemctl disable firewalld
      [ $? -eq 0 ] && echo "Disable firewalld complete."
      else
      echo "Firewalld not install."
   fi
}

# vim config
vim_config() {
    echo "Starting vim config..."
    /usr/bin/egrep pastetoggle /etc/vimrc >> /dev/null
    if [ $? -eq 0 ];then
       echo "vim already config"
       else
     #  sed -i '$ a\set bg=dark\nset pastetoggle=<F9>' /etc/vimrc
       sed -i '$ a\set bg=dark' /etc/vimrc
    fi

}

# sysctl config

config_sysctl() {
    echo "Staring config sysctl..."
    /usr/bin/cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
    cat > /etc/sysctl.conf << EOF
vm.swappiness = 0
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
fs.suid_dumpable = 0
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_tw_buckets = 8000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.conf.all.rp_filter = 1
EOF

    /usr/sbin/sysctl -p
    [ $? -eq 0 ] && echo "Sysctl config complete."
}


# ipv6 config
disable_ipv6() {
    echo "Starting disable ipv6..."
    sed -i '$ a\net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
    sed -i '$ a\AddressFamily inet' /etc/ssh/sshd_config
    systemctl restart sshd
    /usr/sbin/sysctl -p
}

# password config
password_config() {
    # /etc/login.defs  /etc/security/pwquality.conf
    sed -i 's/PASS_MIN_LEN    5/PASS_MIN_LEN    8/g' /etc/login.defs
    authconfig --passminlen=8 --update                   #at least 8 character
    authconfig --passminclass=2 --update                 #at least 2 kinds of Character class
    authconfig --enablereqlower --update                 #at least 1 Lowercase letter
    authconfig --enablerequpper --update                 #at least 1 Capital letter
    [ $? -eq 0 ] && echo "Config password rule complete."
}

other() {
# Record command
# lock user when enter wrong password root 10s others 180s
sed -i '1aauth       required     pam_tally2.so deny=3 unlock_time=180 even_deny_root root_unlock_time=10' /etc/pam.d/sshd
}

# disable no use service
disable_serivces() {
    systemctl stop postfix && systemctl disable postfix
    [ $? -eq 0 ] && echo "Disable postfix service complete."
}

#main function
main(){
    set_name
    user_del
#    system_update
    repo_update
    timezone_config
    selinux_config
    ulimit_config
    sshd_config
    disable_firewalld
    vim_config
    config_sysctl
    disable_ipv6
    password_config
    disable_serivces
    other
}

# execute main functions
main
echo "+------------------------------------------------------------------------+"
echo "|            To initialization system all completed !!!                  |"
echo "+------------------------------------------------------------------------+"
