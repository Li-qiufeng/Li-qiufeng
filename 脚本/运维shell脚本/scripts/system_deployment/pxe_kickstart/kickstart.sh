#!/bin/env bash

systemctl stop firewalld
systemctl disable firewalld
sed -ri '/^SELINUX/c\SELINUX=disabled' /etc/selinux/config
setenforce 0

cp /etc/sysconfig/network-scripts/ifcfg-eth0{,.bak}
>/etc/sysconfig/network-scripts/ifcfg-eth0 
cat>> /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
	NAME="eth0"
	ONBOOT=yes
	NETBOOT=yes
	BOOTPROTO=none
	TYPE=Ethernet
	DEFROUTE=yes
	PEERDNS=yes
	PEERROUTES=yes
	IPV4_FAILURE_FATAL=no
	IPADDR=192.168.254.128
	NETMASK=255.255.255.0
	EOF
systemctl restart network

mkdir -p /var/ftp/centos{6u8,7u3}
mount /dev/sr0 /var/ftp/centos6u8/
mount /dev/sr1 /var/ftp/centos7u3/
cat>>/etc/rc.local<<-EOF
mount /dev/sr0 /var/ftp/centos6u8/
mount /dev/sr1 /var/ftp/centos7u3/
EOF
chmod +x /etc/rc.d/rc.local

mkdir /etc/yum.repos.d/repo.backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo.backup/
cat>>/etc/yum.repos.d/centos7u3.repo<<-EOF
	[centos7u3]
	name=centos7u3
	baseurl=file:///var/ftp/centos7u3
	gpgcheck=0
	enabled=1
	EOF
yum repolist
yum -y install dhcp tftp-server vsftpd xinetd syslinux

>/etc/dhcp/dhcpd.conf
cat>>/etc/dhcp/dhcpd.conf<<-EOF
subnet 192.168.254.0 netmask 255.255.255.0{
	range 192.168.254.128 192.168.254.254;
	next-server	192.168.254.128;
	filename	"pxelinux.0";
}
EOF
systemctl restart dhcpd
systemctl enable dhcpd

mkdir /var/lib/tftpboot/centos{6u8,7u3}
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot
cp /var/ftp/centos7u3/isolinux/vesamenu.c32 /var/lib/tftpboot
cp /var/ftp/centos6u8/isolinux/vmlinuz /var/lib/tftpboot/centos6u8
cp /var/ftp/centos6u8/isolinux/initrd.img /var/lib/tftpboot/centos6u8
cp /var/ftp/centos7u3/isolinux/vmlinuz /var/lib/tftpboot/centos7u3
cp /var/ftp/centos7u3/isolinux/initrd.img /var/lib/tftpboot/centos7u3
mkdir /var/lib/tftpboot/pxelinux.cfg
cp $PWD/default /var/lib/tftpboot/pxelinux.cfg/
sed -ri '/disable/c\\tdisable\t\t\t=no' /etc/xinetd.d/tftp
systemctl restart xinetd
systemctl enable xinetd

cp $PWD/centos* /var/ftp/
systemctl start vsftpd
systemctl enable vsftpd
