#!/usr/bin/bash
PS3="Your choice is[5 for quit]: "

while :
do
select choice in disk_partition filesystem cpu_load mem_util quit
do
	case "$choice" in
		disk_partition)
			fdisk -l
			break
			;;
		filesystem)
			df -h
			break
			;;
		cpu_load)
			uptime
			break
			;;
		mem_util)
			free -m
			break
			;;
		quit)
			exit	
			;;
		*)
			echo "error"
			exit
	esac	
done
done
