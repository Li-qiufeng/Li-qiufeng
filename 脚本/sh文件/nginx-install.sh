#!/usr/bin/env bash 
#install nginx by blackmed
#Download the installation package 1.12.2

		#Test network download installation package
		ping -c 1 www.baidu.com >/dev/null
		if [ $? -eq 0 ];then
			echo "The network is available to download the installation package."
		        wget -O /nginx-1.12.2.tar.gz http://nginx.org/download/nginx-1.12.2.tar.gz
		fi
		#Detecting yum, setting up the setting up environment
		yum_list=`yum repolist | awk '/repolist:/{print $NF}' | wc -m`
		if [ $yum_list -ge 5 ];then
			echo "====================="
			echo "Being installed ...."
			echo "====================="
			yum -y install gcc* >/dev/null
			if [ $? -eq 0 ];then	
				echo "====================="
				echo "Install successfully.."
				echo "====================="
			fi
		else
			echo "Please check the yum configuration"
		fi
		#install ngixn
		cd /
		tar xvf nginx-1.12.2.tar.gz  
		cd /nginx-1.12.2
		./configure  --prefix=/usr/local/nginx --enable -so  --enable -modules=all --enable -ssl
		make && make install
		cd /usr/local/nginx/sbin
		./nginx
		systemctl status nginx 
		if [ $? -eq 0 ];then
			echo "****************************************************************"
			echo "The source nginx is installed successfully and has been started."
			echo "****************************************************************"
		fi
	}
nginx
