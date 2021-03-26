#!/usr/bin/env bash
# 基础环境配置
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -ri '/^SELINUX/c\SELINUX=disabled' /etc/selinux/config
#cobbler安装
yum -y install epel-release
yum -y install cobbler cobbler-web tftp-server dhcp httpd xinetd
systemctl start httpd cobblerd
systemctl enable httpd cobblerd
#配置cobbler
cobbler check
#开启cobbler的命令配置
sed -ri '/allow_dynamic_settings:/c\allow_dynamic_settings: 1' /etc/cobbler/settings
systemctl restart cobblerd
# server
cobbler setting edit --name=server --value=192.168.2.130

# next_server
cobbler setting edit --name=next_server --value=192.168.2.130

# tftp-server
sed -ri '/disable/c\disable = no' /etc/xinetd.d/tftp
systemctl enable xinetd
systemctl restart xinetd

# boot-loaders (e.g. pxelinux.0)
cobbler get-loaders

# rsyncd
systemctl start rsyncd
systemctl enable rsyncd

# debmirror [optional]

# pykickstart
yum -y install pykickstart

# default password
openssl passwd -1 -salt `openssl rand -hex 4` 'tianyun'
$1$9da8d30f$IzwrMCRrCDsnhp1WOAK5k.
cobbler setting edit --name=default_password_crypted --value='$1$9da8d30f$IzwrMCRrCDsnhp1WOAK5k.'

# fencing tools [optional]
yum -y install fence-agents

# manage_dhcp
cobbler setting edit --name=manage_dhcp --value=1
vim /etc/cobbler/dhcp.template
# cobbler centos6
mount /dev/sr0 /media
cobbler import --path=/media --name=centos6.8 --arch=x86_64   #倒入镜像文件
cobbler distro report --name=centos6.8-x86_64    #创建distros
cobbler profile report --name=centos6.8-x86_64   #创建profile
cd /var/lib/cobbler/kickstarts   #ks模板文件
cp -rf sample_end.ks centos6.ks
vim centos6.ks
install
text
keyboard us
lang en_US
timezone  Asia/ShangHai
rootpw --iscrypted $default_password_crypted
auth  --useshadow  --enablemd5
firewall --disabled
selinux --disabled
url --url=$tree

zerombr
bootloader --location=mbr
clearpart --all --initlabel
part /boot --fstype=ext4 --size=500
part swap --size=1024
part / --fstype=ext4 --grow --size=200

$yum_repo_stanza
$SNIPPET('network_config')
skipx
firstboot --disable
reboot

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
@core
@base
httpd
wget
lftp
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps

sed -ri "/^#UseDNS/c\UseDNS no" /etc/ssh/sshd_config
sed -ri "/^GSSAPIAuthentication/c\GSSAPIAuthentication no" /etc/ssh/sshd_config
%end

cobbler profile edit --name=centos6.8-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos6.ks
cobbler profile report --name=centos6.8-x86_64 | grep kick  
#ip自动获取，主机名默认
cobbler profile add --name=web-server --distro=centos6.8-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos6.ks
#指定的主机（预安装主机MAC）能自动选择profile，而且设置静态的IP、主机名..
cobbler system add \
--name=bj-web-01.tianyun.com \
--profile=centos6u6-x86_64 \
--mac=00:0C:29:74:50:3E \
--hostname=bj-web-01.tianyun.com \
--ip-address=192.168.122.100 \
--netboot-enabled=Y \
--gateway=192.168.122.1 \
--static=1 \
--name-servers=8.8.8.8 \
--interface=eth0

# 查看配置
cobbler list
cobbler report
# Cobbler Centos7
mount /dev/sr0 /media
cobbler import --path=/media --name=centos7u3 --arch=x86_64
cd /var/lib/cobbler/kickstarts
cp centos6.ks centos7.ks
vim centos7.ks

install
text
keyboard us
lang en_US
timezone  Asia/ShangHai
rootpw --iscrypted $default_password_crypted
auth  --useshadow  --enablemd5
firewall --disabled
selinux --disabled
url --url=$tree

zerombr
bootloader --location=mbr
clearpart --all --initlabel
part /boot --fstype=xfs --size=500
part swap --size=1024
part / --fstype=xfs --grow --size=200

$yum_repo_stanza
$SNIPPET('network_config')
skipx
firstboot --disable
reboot

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
@^minimal
@core
httpd
wget
lftp
vim-enhanced
bash-completion
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps

sed -ri "/^#UseDNS/c\UseDNS no" /etc/ssh/sshd_config
sed -ri "/^GSSAPIAuthentication/c\GSSAPIAuthentication no" /etc/ssh/sshd_config
systemctl enable httpd
%end

cobbler profile edit --name=centos7u3-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos7.ks
cobbler profile report --name=centos7u3-x86_64 | grep kick

cobbler profile edit --name=centos7u3-x86_64 --kopts='net.ifnames=0 biosdevname=0'
cobbler profile report --name=centos7u3-x86_64


cd /var/lib/cobbler/kickstarts
cp centos7.ks centos7-webserver.ks
cobbler profile add --name="centos7-web-server" --distro="centos7u3-x86_64" --kickstart="/var/lib/cobbler/kickstarts/centso7-webserver.ks" --kopts="net.ifnames=0 biosdevname=0"
#指定的主机（预安装主机MAC）能自动选择profile，而且设置静态的IP、主机名...
cobbler system add --name="" --profile="" --interface="eth0" --mac=""
cobbler system add --name="" --profile="" --interface="eth0" --mac="" --hostname=""  --ip-address="" --subnet="255.255.255.0" --gateway="" --name-servers="" --static="1" --netboot-enabled="Y"
