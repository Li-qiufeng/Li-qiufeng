#!/bin/bash
#stop vm
#v1.0
#name time
source super_menu.sh
down_vmhost(){
        while :
        do
		clear
		down_vm_menu
                echo -en "\e[1;32mOperation sequence number: \e[0m"
                read down_mode
                case $down_mode in

			     1)	clear
				down_menu
				while :
                                do
                                printf "\n\e[1;32mEnter the shutdown virtual machine: \e[0m"
                                read down_vm_num
                                local down_total=$(cat $PWD/tmp/down_list.txt | wc -l)
                                if [[ "$down_vm_num" == "q" ]]; then
                                        printf "\n\e[1;31mAre you Sure[y]: \e[0m"
					read affirm
						if [ "$affirm" = "y" ]; then
							break
						else
							continue
						fi
                                elif [[ ! $down_vm_num =~ ^[0-9]+$ ]];then
                                        printf "\n\e[1;31mPlease enter an integer [1-$down_total] \e[0m"
                                        continue
                                fi
                                local down_vm_name=$(sed -n "$down_vm_num p" $PWD/tmp/down_list.txt | cut -d ' ' -f 3)
                                if [[ $down_vm_num -gt 0 && $down_vm_num -le $down_total ]]; then

                                        virsh shutdown $down_vm_name
                                else
                                        printf "\n\e[1;31mPlease enter an integer [1-$down_total] \e[0m"
                                fi
                                done
                                ;;
                        2)
				clear
				down_menu
                                echo -en "\e[1;31mMake sure all are closed[y]: \e[0m"
                                read down_all
                                if [ "$down_all" != "y" ]; then
                                        continue
                                else
                                  	while read line
                                        do
                                                local down_name=$(echo $line |awk -F " " '{print $NF}')
                                                virsh shutdown $down_name
                                  	done< $PWD/tmp/down_list.txt
					
                                fi
                                ;;
                        q)
                                 printf "\n\e[1;31mConfirm exit[y]: \e[0m"
                                read down_q
                                if [ "$down_q" = "y" ]; then
                                        break
                                else
					continue
                                fi
				 ;;
                        '')
                                 printf "\n\e[1;31mPlease enter an integer [1 & 2]\n\e[0m"
                                continue
				;;
                        *)

                                printf "\n\e[1;31mPlease enter an integer [1 & 2]\n\e[0m"
                                continue
				;;

                esac
        done
        }
#down_vmhost

