#!/usr/bin/bash
#v1.0 by tianyun
for ip in `cat ip.txt`
do
	{
	ping -c1 -W1 $ip &>/dev/null
	if [ $? -eq 0 ];then
		ssh $ip "sed -ri '/^#UseDNS/cUseDNS no' /etc/ssh/sshd_config"
		ssh $ip "sed -ri '/^GSSAPIAuthentication/cGSSAPIAuthentication no' /etc/ssh/sshd_config"
		ssh $ip "systemctl stop firewalld; systemctl disable firewalld"
		ssh $ip "sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config"
		ssh $ip "setenforce 0"
	fi
	}&
done
wait
echo "all ok..."
