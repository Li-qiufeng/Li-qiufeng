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

menu() {
	clear
	echo "################################"
	echo -e "\t1 php-5.6"
	echo -e "\t2 php-7.0"
	echo -e "\t3 php-7.1"
	echo -e "\th help"
	echo -e "\tq exit"
	echo "################################"
}
menu

while :
do
	read -p "version[1-3]: " version
	case "$version" in
	1)
		install_php56
		;;
	2)
		install_php70
		;;
	3)
		install_php71
		;;
	q)
		exit
		;;
	h)
		menu
		;;
	"")
		;;
	*)
		echo "error"
	esac
done
