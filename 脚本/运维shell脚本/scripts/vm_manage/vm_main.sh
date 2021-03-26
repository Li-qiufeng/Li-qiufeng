#!/bin/env bash
# The virtual machine manages the main script
# v1.0
# name  time
source super_menu.sh
source open_vm.sh
source conn_vm.sh    
source stop_vm.sh  
Master_method()
	{	
	while :
	do			
		clear
		main_menu
		echo -en "\e[1;32mPlease enter an operation request：  \e[0m"
		read master
		case $master in
			1)
				clear
				open_vmhost
				;;
			2)
				clear
				down_vmhost
				;;
			3)
				clear
				connect_vm
				;;
			q)
				printf "\n\e[1;31mConfirm exit[y]: \e[0m"
				read down_q
				if [ "$down_q" = "y" ]; then
						exit
					else
						continue
					fi
				;;
			'')
				echo "\n\e[1;3Input cannot be empty[1-4]\e[0m"
				continue
				;;
			*)
				echo "\n\e[1;31mInput error, please re-enter[1-4]\e[0m"
				continue
				;;

		esac
	done
	}
Master_method
