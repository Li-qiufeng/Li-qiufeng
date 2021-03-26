#!/usr/bin/bash
read -p "Please input a ip: " ip

ping -c1 ${ip} &>/dev/null
if [ $? -eq 0 ]; then
	echo "${ip}new is up."
else
	echo "${ip} is down."
fi
