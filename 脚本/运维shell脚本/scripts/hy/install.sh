#!/bin/bash
dir=/etc/httpd/conf.d
name=test.conf
webdir=/var/www
yum -y install httpd
if [ $? -eq 0 ];then
	systemctl stop firewalld
	systemctl disable firewalld
	sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config
	echo "test" > $webdir/index.html
	cat >> $dir/$name << EOF
<VirtualHost *:80>
	ServerName www.test.hy
	DocumentRoot $webdir
</VirtualHost>
<Directory $webdir>
	Require all granted
</Directory>
EOF
	systemctl restart httpd
else
	echo "error"
fi

