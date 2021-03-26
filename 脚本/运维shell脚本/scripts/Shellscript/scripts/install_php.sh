#!/usr/bin/bash
#install php
install_php56() {
	echo "install php5.6......"
}

install_php70() {
	echo "install php7.0......"
}

install_php71() {
	echo "install php7.1......"
}
while :
do
	echo "################################"
	echo -e "\t1 php-5.6"
	echo -e "\t2 php-7.0"
	echo -e "\t3 php-7.1"
	echo -e "\tq exit"
	echo "################################"

	read -p "version[1-3]: " version
	if [ "$version" = "1" ];then
		install_php56	
	elif [ "$version" = "2" ];then
		install_php70
	elif [ "$version" = "3" ];then
		install_php71
	elif [ "$version" = "q" ];then
		exit
	else
		echo "error"	
	fi
done
