#!/bin/bash
#v1.0 name time
main_menu()
	{
	printf "\e[1;34m#########################################################\e[0m\n"
	printf "\e[1;34m#                                                       #\e[0m\n"
	printf "\e[1;34m#      -*-Welcome to virtual machine management-*-      #\e[0m\n"
        printf "\e[1;34m#            ===============================            #\e[0m\n"
        printf "\e[1;34m#                                                       #\e[0m\n"
        printf "\e[1;34m#            1. Open virtual machine                    #\e[0m\n"
        printf "\e[1;34m#            2. Turn off the virtual machine            #\e[0m\n"
        printf "\e[1;34m#            3. Connect virtual machine                 #\e[0m\n"
        printf "\e[1;34m#            4. Batch operation                         #\e[0m\n"
        printf "\e[1;34m#            q. Quit                                    #\e[0m\n"
        printf "\e[1;34m#                                                       #\e[0m\n"
        printf "\e[1;34m#########################################################\e[0m\n"
	ll -d $PWD/tmp &>/dev/null
	if [ $? -ne 0 ]; then
		mkdir -p $PWD/tmp
	fi
	}

open_vm_menu()
        {
        printf "\e[1;34m#############################################\e[0m\n"
	printf "\e[1;34m#                                           #\e[0m\n"
	printf "\e[1;34m#        -*- Open virtual machine-*-        #\e[0m\n"
        printf "\e[1;34m#       =============================       #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       1. Custom open virtual machine      #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       2. Turn on all virtual machines     #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       q. Back to top menu                 #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#############################################\e[0m\n"
        }
down_vm_menu()
        {
        printf "\e[1;34m#############################################\e[0m\n"
	printf "\e[1;34m#                                           #\e[0m\n"
	printf "\e[1;34m#        -*- Down virtual machine-*-        #\e[0m\n"    
        printf "\e[1;34m#       =============================       #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       1. Custom down virtual machine      #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       2. Turn off all virtual machines    #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       q. Back to top menu                 #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#############################################\e[0m\n"

        }
conn_vm_menu()
        {
        printf "\e[1;34m#############################################\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#        -*- Conn virtual machine-*-        #\e[0m\n"    
        printf "\e[1;34m#       =============================       #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       1. Custom conn virtual machine      #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       2. Conn all virtual machines        #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#       q. Back to top menu                 #\e[0m\n"
        printf "\e[1;34m#                                           #\e[0m\n"
        printf "\e[1;34m#############################################\e[0m\n"

        }
old_ssh_key()
	{
	printf "\e[1;34m#######################################################\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        printf "\e[1;34m#            -*- Delete the SSH key -*-               #\e[0m\n"
        printf "\e[1;34m#         ================================            #\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        echo $(awk -F" " '{print $1}' $HOME/.ssh/known_hosts)|awk '{len=split($0,a);for(i=1;i<=len;i++)printf ""i": " a[i] "\n"}'>$PWD/tmp/old_ssh_key.txt
        while read line
        do
                printf "\e[1;34m#\t\t%-s%-20s %15s#\e[0m \n" $line

        done < $PWD/tmp/old_ssh_key.txt
        printf "\e[1;34m#               q: Back to top menu                   #\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        printf "\e[1;34m#######################################################\e[0m\n"                   
	}
conn_menu()
	
	>$PWD/tmp/connulist.txt
	run_vm=$(virsh list | awk '{if(NR!=1)print $2}')
	local i=0
	for line in $run_vm
	do
		vm_mac=$(virsh dumpxml $line | grep 'mac address' | awk -F '=' '{print $2}'| awk -F '/' '{print $1}'| sed s/\'//g)
		vm_ip=$(arp -n | grep $vm_mac |awk '{print $1}')
		vm_name[++i]=$line 
		vm_ip_list[++j]=$vm_ip
	done
	printf "\e[1;34m#############################################\e[0m" 
	printf "\e[1;34m#                                           #\e[0m"
	printf "\e[1;34m#     -*- Connect virtual machine -*-       #\e[0m"
        printf "\e[1;34m#     ===============================       #\e[0m"
        printf "\e[1;34m#                                           #\e[0m"
        for i in ${!vm_name[@]}
        do
	printf "\e[1;34m#\t0%-2s: %-14s -- %15s \e[0m \n" $i: ${vm_name[$i]} ${vm_ip_list[$i]}
	echo	$i: ${vm_name[$i]} -- ${vm_ip_list[$i]} >> $PWD/tmp/conn_list.txt
	done
	printf "\e[1;34m#       q: Back to top menu                 #\e[0m"
        printf "\e[1;34m#                                           #\e[0m"
        printf "\e[1;34m#############################################\e[0m"
	unset vm_name
	unset vm_ip_list
	conn_menu()
        {
        >$PWD/tmp/conn_list.txt
        run_vm=$(virsh list | awk '{if(NR!=1)print $2}')
        local i=0
        for line in $run_vm
        do
                vm_mac=$(virsh dumpxml $line | grep 'mac address' | awk -F '=' '{print $2}'| awk -F '/' '{print $1}'| sed s/\'//g)
                vm_ip=$(arp -n | grep $vm_mac |awk '{print $1}')
                vm_name[++i]=$line
                vm_ip_list[++j]=$vm_ip
        done
        printf "\e[1;34m#######################################################\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        printf "\e[1;34m#          -*- Connect virtual machine -*-            #\e[0m\n"
        printf "\e[1;34m#          ===============================            #\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        for i in ${!vm_name[@]}
        do
        if [ $i -le 9 ];then
                printf "\e[1;34m#\t0%-2s: %-13s-- %15s %8s #\e[0m \n" $i ${vm_name[$i]} ${vm_ip_list[$i]}
        else
                printf "\e[1;34m#\t%-2s: %-13s-- %15s %8s #\e[0m \n" $i ${vm_name[$i]} ${vm_ip_list[$i]}
        fi
        echo    $i: ${vm_name[$i]} -- ${vm_ip_list[$i]} >> $PWD/tmp/conn_list.txt
        done
        printf "\e[1;34m#               q: Back to top menu                   #\e[0m\n"
        printf "\e[1;34m#                                                     #\e[0m\n"
        printf "\e[1;34m#######################################################\e[0m\n"
        unset vm_name
        unset vm_ip_list
	}
#conn_menu
open_menu()
	{
	>$PWD/tmp/open_list.txt
	local k=0
	for vmhost_name in $(virsh list --state-shutoff | awk '{if(NR!=1) print $2}')
	do
		vm_name_list[++k]=$vmhost_name
	done
	printf "\e[1;34m############################################################################\e[0m\n"
	printf "\e[1;34m#                                                                          #\e[0m\n"
	printf "\e[1;34m#                    -*- Virtual machine boot list -*-                     #\e[0m\n"
	printf "\e[1;34m#          ======================================================          #\e[0m\n"
	printf "\e[1;34m#                                                                          #\e[0m\n"
	for vm_id in ${!vm_name_list[@]}
	do
		if [[ $vm_id -le 9 && $[$vm_id%2] -eq 1 ]];then
			printf "\e[1;34m#\t0%-2s: %-13s %8s \e[0m \b" $vm_id ${vm_name_list[$vm_id]} shut-off
		elif [[ $vm_id -le 9 && $[$vm_id%2] -eq 0 ]];then
			printf "\e[1;34m\t0%-2s: %-13s %8s \t   #\e[0m \n" $vm_id ${vm_name_list[$vm_id]} shut-off
		elif [[ $vm_id -ge 10 && $[$vm_id%2] -eq 1 ]];then
			printf "\e[1;34m#\t%-2s : %-13s %8s \e[0m \b" $vm_id ${vm_name_list[$vm_id]} shut-off
		elif [[ $vm_id -ge 10 && $[$vm_id%2] -eq 0 ]];then
			printf "\e[1;34m\t%-2s : %-13s %8s \t   #\e[0m \n" $vm_id ${vm_name_list[$vm_id]} shut-off
		fi
	done
	printf "\e[1;34m#                                                                          #\e[0m\n"
	printf "\e[1;34m#                        q: Back to top menu                               #\e[0m\n"
	printf "\e[1;34m#                                                                          #\e[0m\n"
	printf "\e[1;34m############################################################################\e[0m\n"
	for vm_id in ${!vm_name_list[@]}
	do
		if [ $vm_id -le 9 ];then
			printf "0%-2s: %-13s %-8s \n" $vm_id ${vm_name_list[$vm_id]} >> $PWD/tmp/open_list.txt
		else
			printf "%-2s : %-13s %-8s \n" $vm_id ${vm_name_list[$vm_id]} >> $PWD/tmp/open_list.txt
		fi
	done
	unset vm_name_list

	}
#open_menu
down_menu()
	{
	 #clear
        >$PWD/tmp/down_list.txt
        local k=0
	for vmdown_name in $(virsh list | awk '{if(NR!=1) print $2}')
        do
                vm_down_list[++k]=$vmdown_name
        done
	printf "\e[1;34m############################################################################\e[0m\n"
        printf "\e[1;34m#                                                                          #\e[0m\n"
	printf "\e[1;34m#                   -*- Virtual machine shutdown list -*-                  #\e[0m\n"
        printf "\e[1;34m#          ======================================================          #\e[0m\n"
        printf "\e[1;34m#                                                                          #\e[0m\n"
        for vm_down_id in ${!vm_down_list[@]}
        do
                if [[ $vm_down_id -le 9 && $[$vm_down_id%2] -eq 1 ]];then
                        printf "\e[1;34m#\t0%-2s: %-13s %8s \e[0m \b" $vm_down_id ${vm_down_list[$vm_down_id]} running
                elif [[ $vm_down_id -le 9 && $[$vm_down_id%2] -eq 0 ]];then
                        printf "\e[1;34m\t0%-2s: %-13s %8s \t   #\e[0m \n" $vm_down_id ${vm_down_list[$vm_down_id]} running
                elif [[ $vm_down_id -ge 10 && $[$vm_down_id%2] -eq 1 ]];then
                        printf "\e[1;34m#\t%-2s : %-13s %8s \e[0m \b" $vm_down_id ${vm_down_list[$vm_down_id]} running
                elif [[ $vm_down_id -ge 10 && $[$vm_down_id%2] -eq 0 ]];then
                        printf "\e[1;34m\t%-2s : %-13s %8s \t   #\e[0m \n" $vm_down_id ${vm_down_list[$vm_down_id]} running
                fi
        done
        printf "\e[1;34m#                                                                          #\e[0m\n"
        printf "\e[1;34m#                        q: Back to top menu                               #\e[0m\n"
        printf "\e[1;34m#                                                                          #\e[0m\n"
        printf "\e[1;34m############################################################################\e[0m\n"
        for vm_down_id in ${!vm_down_list[@]}
        do
                if [ $vm_down_id -le 9 ];then
                        printf "0%-2s: %-13s %-8s \n" $vm_down_id ${vm_down_list[$vm_down_id]} >> $PWD/tmp/down_list.txt
                else
                        printf "%-2s : %-13s %-8s \n" $vm_down_id ${vm_down_list[$vm_down_id]} >> $PWD/tmp/down_list.txt

		fi
	done
	unset vm_down_list
		}
#down_menu
