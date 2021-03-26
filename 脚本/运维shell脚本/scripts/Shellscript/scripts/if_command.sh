#!/usr/bin/bash
command1=/etc/hosts

if command -v $command1 &>/dev/null;then
	:	
else
	echo "yum install xx"
fi
