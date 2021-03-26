#!/bin/bash
#Kvm  manager  v1.5
#Data  2016/06/08
###############################  Cereat Directories  #############################

#ls /home/virtimages &> /dev/null || mkdir /home/virtimages
#ls /etc/libvirt/qemu/backxml &> /dev/mull || mkdir /etc/libvirt/qemu/backxml

#[ ! -d $vm_xml_bak_dir ]  && mkdir $vm_xml_bak_dir
##################################################################################
#KVM 虚拟机虚拟磁盘文件存放目录
vm_images_dir=/home/virtimages

#KVM 虚拟机XML配置文件存放目录
vm_xml_dir=/et/libvirt/qemu

#KVM Domain XML配置文件初始备份目录
vm_xml_bak_dir=/etc/libvirt/qemu/backxml

#KVM Domain XML配置文件模板
down_sample_xml=ftp://192.168.124.1/vms/centos6sample.xml
sample_xml=$vm_xml_dir/centos6sample.xml

#KVM Domain后端镜像
down_back_image=ftp://192.168.124.1./vms/centos6.image
back_image=/home/virtimages/centos6.image

##################################################################################

main_menu (){
	cat <<-eof
    #############################################################################
                                                                                 
                          KVM  管理工具  v1.4                                
                                                                                 
　    注意！！！！！！！！                                                       
      初次运行脚本，请先定义脚本的变量；用命令: sudo vim $PWD/kvm_manager.sh     
                                                                                 
      1.  安装虚拟化软件                   A.  批量恢复虚拟机                    
      2.  自动化安装虚拟机                 B.  批量删除虚拟机                    
      3.  给指定虚拟机添加磁盘             C.  恢复指定单个或多个任意虚拟机      
      4.  给指定虚拟机添加内存             D.  删除指定单个或多个任意虚拟机      
      5.  批量部署Linux虚拟机              S.  查看所有虚拟机                    
      6.  批量部署Windows虚拟机            Q.  退出KVM管理工具                   
                                                                                 
    #############################################################################
	eof

}

###########################  Rebuild Domain  ###################################

rebuild_domain (){
		rm -f  $vm_images_dir/${domain_name}.qcow2
		[ ! -f $back_image ]  &&  wget -nc $down_back_imagei  -O  $back_image
		
		[ ! -f $sample_xml ]  &&  wget -nc $down_sample_xml   -O  $sample_xml
		virsh destroy   ${domain_name}
		virsh undefine  ${domain_name}
		qemu-img create -f qcow2 -b $back_image $vm_images_dir/${domain_name}.qcow2
		virsh  define   ${vm_xml_bak_dir}/${domain_name}.xml
}

###########################  Delete  Domain   ###################################

delete_domain (){
	  
				virsh destroy   $domain_name
				virsh undefine  ${domain_name}
				rm -f	$vm_images_dir/${domain_name}.qcow2
				rm -f	$vm_xml_dir/${domain_name}.xml
				rm -f	$vm_xml_bak_dir/${domain_name}.xml
}

########################### Install   KVM  Software  #############################

install_kvm_soft() {
#当你的环境是centos6.x的情况下请打开一下选项
#	service libvirtd restart
	systemctl restart libvirtd  
	pgrep  libvirtd
	if   [ $? -eq 0 ];then
		sleep 5
		echo "kvm is runing..."
		virsh list --all
	else
		yum -y groupinstall "Virtual*" &> /dev/null
#当你的环境是centos6.x的情况下请打开一下选项
#		service libvirtd  restart  
#		chkconfig libvirtd on
		systemctl restart libvirtd 
		systemctl enable libvirtd
		clear
		echo "kvm install  finish..."
	fi
}


################## Install   one  Linux  Vitaul  Host  #######################

install_linux_domain (){
		read -p "请输入要创建的虚拟机name,cpu,mem[e.g.xiguatian 1 512]" v_name v_cpu v_mem
		echo "你创建的虚拟机name: $v_name"
		echo "你创建的虚拟机cpu: $v_cpu"
	#	echo "你创建的虚拟机maxmem: $v_maxmem"
		echo "你创建的虚拟机mem: $v_mem"
		read -p  "Are you sure? [y|Y] " yn
		case $yn in
		y|Y|"\Enter")
			install=$(which virt-install)
			${install} \
			--graphics vnc \
			--name $v_name \
			--memory $v_mem,maxmemory=1024 \
			--vcpus $v_cpu \
			--arch x86_64 \
			--hvm \
			--disk $vm_images_dir/${v_name}.qcow2,size=10,format=qcow2,cache=writeback,io=threads,bus=virtio \
			--network network=default,model=virtio \
			--location ftp://192.168.124.1/centos6 \
			--extra-args="ks=ftp://192.168.124.1/ks/centos6.ks"
			\cp  -p $vm_xml_dir/$v_name.xml  $vm_xml_bak_dir/$v_name.xml
			;;
		n|N)
			exit
			;;
		*)
			echo  "输入错误！请重新选择： "
			main_menu
			;;
		esac
}

#####################   Add   Disk   Diver  #######################

add_disk (){
		virsh  list  --all
		read -p "输入虚拟机 Domain Name：" domain_name
		cat <<-eof
		请确认要添加硬盘的虚拟机是启动状态
		eof
		while :
		do
				read -p "需要启动虚拟机$domain_name吗？[y|n]" yn1
				case $yn1 in
				y|yes|Y)
					echo "$domain_name is starting..."
					sleep 5
					virsh start $domain_name
					break
					;;
				n|N)
					break
					;;
				' ')
					echo "你必须做出你的选择[y|n]"
					:
					;;
				*)
					echo "你必须做出你的选择[y|n]"
					:
					;;
				esac
		done
		read -p "输入添加硬盘的容量如【5G】： " dik_num
		echo " "	#添加一行空行
		echo   "Add disk before the hard disk information"
		read -p "请输入要添加虚拟机硬盘的设备名。如：[vdb|vdc]: "  target_blk
		virsh  domblklist $domain_name
		echo "Domain name is: $domain_name"
		echo "Domain name set disk size is: $dik_num"
		read -p "Ary you sure?[ y|n ] To main_menu input [ m|M ]: " yn2 
		
		case $yn2 in 
			y|Y)
				qemu-img create -f qcow2 ${vm_images_dir}/${domain_name}_${target_blk}.qcow2 ${dik_num}
				addblk=${vm_images_dir}/${domain_name}_${target_blk}.qcow2
				virsh attach-disk $domain_name --source $addblk \
				--target $target_blk --targetbus virtio --cache writeback --subdriver qcow2 \
				--persistent  
				echo  "  "
				echo   "Added hard disk information"
				virsh domblklist   $domain_name
				echo "硬盘已添加成功，稍等进入主菜单..."
				sleep 5
				;;
			n|N)
				main_menu
				;;
			*)
				main_menu
				;;
		esac
}

#######################   Add   Memery   #################################

add_mem (){ 
		virsh   list  --all
		read -p "输入虚拟机 Domain Name：" domain_name
		read -p "输入添加内存的容量如【512M】： " mem_num
		echo  "  "
		echo   "Add previous memory information"
		virsh  dominfo  $domain_name
		echo "Domain name is: $domain_name"
		echo "Domain name set memory size is: $domain_name"
		read -p "Ary you sure?[y|n][m Return to main menu]: " yn 

		case $yn in 
			y|Y)
				virsh  setmaxmem  $domain_name $mem_num --config
				virsh  setmem     $domain_name $mem_num --config
				echo  "  "
				echo   "Added memory information"
				virsh  dominfo 	  $domain_name
				;;
			n|N)
				main_menu
				;;
			*)
				main_menu
				;;
		esac
}

#################### Batch  Install Linux  Domains #########################

batch_install_linux_domains (){

	read -p "请输入要安装虚拟机的前缀： " 	vm_prefix
	read -p "请输入要安装虚拟机的数量： "   vm_number
	read -p "请确认你要创建虚拟机的信息，确认创建请输入 [ y|Y ];不创建或要修改请输入 [ n|N ]: " yn 
	case $yn in 
		y|Y)
			[ ! -f $back_image ]  &&  wget -nc ${down_back_image}	-O  $back_image
			[ ! -f ${vm_xml_bak_dir}/centos6sample.xml ]  &&  wget -nc ${down_sample_xml} -O  ${vm_xml_bak_dir}/centos6sample.xml
			
			for i  in `seq -w $vm_number`
			#for i  in $(seq -f "$v_name%02g")
			do
						{
						
						vm_name=${vm_prefix}-${i}
						vm_uuid=$(uuidgen)
						vm_mac="52:54:$(dd if=/dev/urandom count=1 2>/dev/null \
						| md5sum | sed -r 's/^(..)(..)(..)(..).*$/\1:\2:\3:\4/')"
					
						vm_image=${vm_images_dir}/${vm_name}.qcow2
						vm_xml=$vm_xml_bak_dir/${vm_name}.xml
						
						qemu-img create -f qcow2 -b $back_image $vm_image
						\cp -rf $vm_xml_bak_dir/centos6sample.xml  $vm_xml
						sed -i "s#sample_name#$vm_name#"    $vm_xml
						sed -i "s#sample_uuid#$vm_uuid#"    $vm_xml
						sed -i "s#sample_image#$vm_image#"  $vm_xml
						sed -i "s#sample_mac#$vm_mac#"      $vm_xml
						
						virsh define $vm_xml
						}&
			done
			wait
			echo "所有虚拟机均创建完成。"
			;;
		n|N)
			main_menu
			;;	
		*)
			echo "输入错误，程序将退出！！！"
			sleep 5 
			echo "......."
			exit
	esac
}

################################   Batch  Windows  Server  ##############################

batch_install_winserver_domains (){
	echo "bach winserver is ok"
}


##########################  Rebuild Vrual Host ###############################################

batch_rebuild_domains (){
		virsh  list --all
        read -p "请输入你要重置的虚拟机名字前辍和起止号【name-2-6】： " rr
		name=$(echo $rr |awk -F- '{print $1}')
		n1=$(echo $rr |awk -F- '{print $2}')
		n2=$(echo $rr |awk -F- '{print $3}')
        
		for reb in `seq $n1 $n2`
		do
      	  	echo  "你要重置的虚拟机是：$name-$reb"
 		done
        
		cat <<-eof
                 ×××××××××××××××××××××××××××××××××××x
                 ×      确认请输入[y|Y]             ×
                 ×      退出请输入[n|N]             ×
                 ×      返回上一级菜单[q|Q]         ×
                 ×××××××××××××××××××××××××××××××××××x
		eof
        read -p "请选择你操作：" yn
        
		case  $yn in
        y|Y|yes|YES)
                    for i in `seq	n1 n2`
	                do
						{
						rebuild_name= ${name}-${i}
                    	domain_name=${rebuild_name}
						rebuild_domain
                    	}&
					done
					wait
		    echo "虚拟机已重置成功！"
                    virsh list --all	
					main_menu
                    ;;
       n|N|no|NO)
                    exit
                    ;;
       q|Q)
                    main_menu
                   ;;
       *)
                    echo "输入错误请重新输入: "
                  	batch_rebuild_domains 
                    ;;
       esac
}

#################################    Batch  Delete Domain    #########################################

batch_del_domains (){
        virsh  list --all
        read -p "请输入你要删除的虚拟机名字例如：[name-1]或者[name-3-5]： " nn
		name=$(echo $nn |awk -F- '{print $1}')      
		n1=$(echo $nn |awk -F- '{print $2}')
		n2=$(echo $nn |awk -F- '{print $3}')
        
		for del in `seq $n1 $n2`
		do
        	echo  "你要删除的虚拟机是：$name-$del"
		done
    	
		cat <<-eof
                 ×××××××××××××××××××××××××××××××××××        
                 ×      确认请输入[y|Y]           ×
                 ×      退出请输入[n|N]           ×
                 ×      返回上一级菜单[q|Q]       ×
                 ×××××××××××××××××××××××××××××××××××
		eof
    	read -p "请选择你操作：" yn
		
		case  $yn in
		y|Y|yes|YES)
			for i in `seq $n1 $n2`
			do
				{
				delname=${name}-${i}
				domain_name=${delname}
				delete_domain
				}&
			done
			wait
			echo "虚拟机已删除成功！"
			virsh list --all
			del-vhost
			;;
		 n|N|no|NO)
			exit
			;;
		q|Q)
		   main_menu
		   ;;
		*)
		   echo "输入错误请重新输入: "
		   batch_del_domains
		   ;;
		esac
}

##############################   Rebuild any one or  more  Domain   ###########################

rebuild_one_more_domain (){
		> $PWD/real_domname.txt
		> $PWD/error_domname.txt
		virsh list --all
		cat <<-eof
         -------------------------------------------
         |                                         |
         |  若是对多个虚拟机进行操作，Domain的名字 |
         |  之间请用空格隔开。例如：test  centos   |
         |                                         |
         -------------------------------------------  
		eof
		read -p "请输入重置虚拟机Domain的名字"   rebuname
		
		if [  -z ${rebuname} ];then
			echo "没有输入任何Domain Name"
			sleep 2
			rebuild_one_more_domain
		fi
		
		for i in $rebuname
		do
				virsh dominfo $i &>/dev/null
			
				if [ $? -eq 0 ];then
				 		echo ${i} >> $PWD/real_domname.txt
				else
						echo ${i} >> $PWD/error_domname.txt
				fi
		done	

		if	[ -s $PWD/error_domname.txt ] || [ -s $PWD/real_domname.txt ];then
				sed -i  '1i  将对下列虚拟机进行重置' $PWD/real_domname.txt
				sed -i  "1i  下列虚拟机不存在或已删除!" $PWD/error_domname.txt
				cat   $PWD/error_domname.txt
				cat   $PWD/real_domname.txt
				read -p  "继续请输入[y|Y],返回请输入[r|R] 返回主菜单 [m|M]: "  rebuyn
				sed  -i  's/将对下列虚拟机进行重置//'    $PWD/real_domname.txt
				sed  -i  "s/下列虚拟机不存在或已删除//"  $PWD/error_domname.txt
				case $rebuyn in
					y|y|yes|YES)
						for i  in	`cat $PWD/real_domname.txt` 
						do
								domain_name=${i}
								rebuild_domain
						done
						
						cat <<-eof
						 -------------------------------------------
						 |                                         |
						 |        对下列虚拟机已重置成功！         |
						 |                                         |
						 -------------------------------------------
						eof
						cat $PWD/real_domname.txt
						
						rm -f $PWD/real_domname.txt
						rm -f $PWD/error_domname.txt
						virsh  list  --all
						exit
						;;
					r|R)
						clear
						rebuild_one_more_domain
						;;
					m|M)
						main_menu
						;;
					'')
						clear
						cat <<-eof
				---------------------------------------------------
				|                 Error!!!                        |
				|  再给你一次机会！万事逃不过 认真 二字！！！"    |
				|                                                 |
				---------------------------------------------------
						eof
						rebuild_one_more_domain
						;;
					*)
						clear
						cat <<-eof
				---------------------------------------------------
				|                 Error !!!                       |
				|  再给你一次机会！万事逃不过 认真 二字！！！"    |
				|                                                 |
				---------------------------------------------------
						eof
						rebuild_one_more_domain
						;;
				esac
		fi		
}

##############################   Delete  any one or more  Domain   #############################

delete_one_more_domain (){

		virsh  list --all
		cat <<-eof
         -------------------------------------------
         |                                         |
         |  若是对多个虚拟机进行操作，Domain的名字 |
         |  之间请用空格隔开。例如：test  centos   |
         |                                         |
         -------------------------------------------  
		eof
		read -p "请输入虚拟机Domain的名字"   delname
		for i  in ${delname}
		do
			domain_name=$i
			delete_domain
		done
		cat <<-eof
         -------------------------------------------
         |                                         |
         |        对下列虚拟机已删除成功！         |
                 ${delname}                         
         |                                         |
         -------------------------------------------
		eof
		virsh  list --all
}

##############################    Main   Menu   #########################################

main_menu
while :
do
	read -p "请选择相应的操作 [q退出]：" choice
	case "$choice"  in
	1)
		install_kvm_soft
		main_menu
		;;
	2)
		install_linux_domain
		clear
		main_menu
		;;
	3)
		add_disk
		main_menu
		;;
	4)
		add_mem
		main_menu
		;;
	5)	
		batch_install_linux_domains
	#	clear
		virsh list --all
		main_menu
		;;
	6)
		batch_install_winserver_domains
		clear
		main_menu
		;;
	a|A)
		batch_rebuild_domains
		clear
		main_menu
		;;
	b|B)
		batch_del_domains
		clear
		main_menu
		;;
	c|C)
		rebuild_one_more_domain
		main_menu
		;;
	d|D)
		delete_one_more_domain
		main_menu
		;;
	s|S)
		virsh list  --all
		;;
	q|Q)	
		exit
		;;
	'')
		true
		;;	
	*)	
		echo "输入错误！请重新输入"
		true
		;;
	esac
done
