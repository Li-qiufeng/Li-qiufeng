#!/bin/env bash
# Connect virtual host
# author xxxx
# v1.0 time
source super_menu.sh
connect_vm()
	{
	clear
	conn_vm_menu
	echo -en "\e[1;32mEnter connection user：\e[0m"
	read vm_user
	while :
	do
		echo -en "\e[1;32mEnter connection mode：\e[0m" 
		read mode
		case $mode in

			1)
				clear
				conn_menu
				echo -en "\e[1;32mEnter connection host：\e[0m"  
				read vm_list
				if [ -z "$vm_list" ];then
					echo -e "\e[1;32mCannot be empty. Please enter the host serial number\e[0m"
					continue
				elif [[ ! $vm_list =~ ^[0-9]+$ ]];then
					echo -e "\e[1;32m Please enter the host serial number\e[0m"
                                        continue
				elif [ "$vm_list"== "q" ];then
					break
				else
				for vm_num in $vm_list
				do
					vm[++i]=$vm_num
				done
				for i in ${!vm[@]}
				do
					vm1_ip=$(sed -n "${vm[$i]}p" $PWD/tmp/conn_list.txt | cut -d ' ' -f 4)
					vm1_name=$(sed -n "${vm[$i]}p" $PWD/tmp/conn_list.txt | cut -d ' ' -f 2)
					ssh $vm_user@$vm1_ip "hostname $vm1_name"
					gnome-terminal --tab -x bash -c "ssh $vm_user@$vm1_ip"
				done
				fi
				;; 
			2)
				clear
				conn_menu
				while read line
				do
					vm2_name=$(echo "$line" | cut -d ' ' -f 2)
					vm2_ip=$(echo "$line" | cut -d ' ' -f 4)
					vmip[k++]=$vm2_ip
					vmname[j++]=$vm2_name
				done < $PWD/tmp/conn_list.txt
				for l in ${!vmip[@]}
				do		
					ssh $vm_user@${vmip[$l]} "hostname ${vmname[$l]}"
					gnome-terminal --tab -x bash -c "ssh $vm_user@${vmip[$l]}"
				done
				unset vmip
				unset vmname
				;;
			q)
				clear
				main_menu
				break
				;;
			'')
				;;
			*)	
				echo "Input error, please re-enter"
		esac
	done 
	} 
