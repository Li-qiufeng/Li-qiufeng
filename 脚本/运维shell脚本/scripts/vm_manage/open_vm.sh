#!/bin/env bash
# Open virtual machine
# V1.0  
source super_menu.sh
confirm(){
	echo -en "\e[1;31mAre your Sure[y/n]: \e[0m"
        read confirm
	if [ "$confirm" == "y" ]; then
		break
	else
		continue
	fi	
	}
open_vmhost(){
	while :
	do
		clear
		open_vm_menu
		echo -en "\e[1;32mOperation sequence number: \e[0m"
		read open_mode
		case $open_mode in
			1)	
				clear
                		open_menu	
				while :
				do
				printf "\n\e[1;32mEnter the open virtual machine: \e[0m"
				read open_vm_num
				local host_total=$(cat $PWD/tmp/open_list.txt | wc -l)
				if [[ "$open_vm_num" == "q" ]]; then
					confirm
				elif [[ ! $open_vm_num =~ ^[0-9]+$ ]];then
					echo "Please enter an integer [1-$host_total]!!!"
					continue
				elif [ -z "$open_vm_num" ];then
					echo "Please enter an integer [1-$host_total]!!!"
                                        continue
				fi
				local open_vm_name=$(sed -n "$open_vm_num p" $PWD/tmp/open_list.txt | cut -d ' ' -f 3)
				if [[ $open_vm_num -gt 0 && $open_vm_num -le $host_total ]]; then

					virsh start $open_vm_name
				else
					echo "Please enter an integer [1-$host_total]!!!"
				fi
				done
				;;
			2)
                                clear
                                open_menu
				echo -en "\e[1;31mAre all the confirmation on [y/n]: \e[0m"
        			read confirm
        			if [ "$confirm" != "y" ]; then
					continue
        			else                     		
					while read line
					do
						local vm_name=$(echo $line |awk -F " " '{print $NF}')
						virsh start $vm_name
							
					done< $PWD/tmp/open_list.txt
				fi
				;;
			
			q)
				confirm
				;;
			'')
				echo "Please enter an integer [1 & 2]"
				;;
			*)	



				echo "Please enter an integer [1 & 2]"
				;;

		esac
	done
	}
#open_vmhost
