#!/usr/bin/bash
#start/stop virtual mation
menu () {
virsh list --all
echo -e "\tEnter a number to change state of centos7u3-[1-5]"
echo -e "\tEnter [m] for menu"
echo -e "\tEnter [start] to start all"
echo -e "\tEnter [stop] to stop all"
echo -e "\tEnter [q] to quit"
}
menu
while :
do
read -p "Enter: " id
if [[ $id =~ [1-5] ]];then
	virsh start centos7u3-$id
	echo "wait for a moment"
	sleep 20
	if [ ! $? -eq 0 ];then
		read -p "Already action.Stop it?[y/n]" action
		if [ "$action" = "y" ];then
		virsh shutdown centos7u3-$id
		fi
	fi
else
case $id in 
win7)
	virsh start win7
	;;
m)
	menu
	;;
start)
	for i in {1..5}
	{
		virsh start centos7u3-$i &>/dev/null
		echo "start centos7u3-$i"
	}
	echo "wait for a moment"
	sleep 20
	;;
stop)
	for i in {1..5}
	{
		virsh shutdown centos7u3-$i &>/dev/null
		echo "stop centos7u3-$i"
	}
	;;
"")
	;;
q)
	exit
	;;
*)
	echo "Enter 1-5"
	;;
esac
fi
done
