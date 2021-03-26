#!/usr/bin/bash
#munu for kvm manager,jump ,jumpserver
menu(){
echo -e "\t1: virtual manager "
echo -e "\t2: ping all hosts"
echo -e "\t3: login virtual machine"
echo -e "\tm: for menu"
}
menu
while :
do
read -p "Choose server: " num
case $num in 
1)
	bash virt-st.sh
	;;
2)
	bash jump.sh
	;;
3)
	bash js.sh
	;;
m)
	menu
	;;
"")
	;;
*)
	echo reenter
	;;
esac
done
