#!/usr/bin/bash
if [ $USER != "root" ];then
	echo "你没有权限!"
	exit
fi

yum -y install httpd
