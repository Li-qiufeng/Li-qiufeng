
while read line
do
	if [ ${#line} -eq 0 ];then
		continue
	else
		vm_name[++i]=$line
	fi
done < /tmp/vm_name.txt
for i in ${!vm_name[@]}
do	
	echo "$i: ${vm_name[$i]}"
done


vm_mac=$(virsh dumpxml centos7u3-1 | grep 'mac address' | awk -F '=' '{print $2}'| awk -F '/' '{print $1}'| sed s/\'//g)
vm_ip=$(arp -a | grep $vm_mac | awk -F ' ' '{print $2}' | sed s/\(//g | sed s/\)//g)
echo $vm_mac
echo $vm_ip
