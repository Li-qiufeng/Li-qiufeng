#!/bin/bash
#select
PS3="You choise is[5 for quit]: "
select choice in disk_partition filesystem cp_load mem_util quit;
do
	case"$choise" in
		disk_partition)
			fdisk -l
			;;
		filesystem )
			df -h
			;;
		cup_load)
			uptime
			;;
		mem_uitl)
			free -m
			;;
		quit)
			break
			;;
		*)
			echo"errer"
			;;
	esac
done
