#!/usr/bin/bash
#system manage
#v1.0 by tianyun 2020-8-20

menu() {
	cat <<-EOF
	#######################################
	#	h. help			      #
	#	f. disk partition	      #
	#	d. filesystem mount           #
	#	m. memory		      #
	#	u. system load                #
	#	q. exit                       #
	#######################################
	EOF
}
menu

while :
do
	read -p "Please input[h for help]: " action
	case "$action" in
	h)	clear; menu;;
	f)	fdisk -l;;
	d)	df -Th;;
	m)	free -m;;
	u)	uptime;;
	q)	break;;
	"")	;;
	*)	echo "error"
	esac
done
echo "finish..."
