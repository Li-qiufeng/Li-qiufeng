#!/usr/bin/env bash
#
# Generate the key
# Content to other computer.
# Ping Test Computer.
# send keys to other computer.
# Author : liuchao


# Generate the key.ssh-keygen commond line.
/bin/mkdir -p /root/.ssh

/usr/bin/expect <<EOF
swapn ssh-keygen -t rsa
expect {
	"(/root/.ssh/id_rsa):"	{ send "\r" ; exp_continue }
	"(empty for no passphrase):"	{ send "\r" ; exp_continue }
	"again:"	{ send "\r" ; exp_continue }
}
EOF

/bin/touch /root/.ssh/authorized_keys
/bin/cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys


# ping IP address exist.
read -p "Please input your want to transfer keys subnet : " Computer_Address

for i in {2..250}
do
{
	ping -c 1 $Computer_Address.$i &> /dev/null
	if [ $? -eq 0 ];then
		echo $Computer_Address.$i >> $PWD/transfer.txt
	else
		echo $Computer_Address.$i &> /dev/null
	fi
}&
wait
done
echo "IP total complete......ok"


#Ctrl Keys to Other Computer.
#Prepare software
/bin/yum -y install expect &> /dev/null
if [ $? -eq 0 ];then
	echo "install expect......ok"
else
	echo "Please check your yum source or install epel extend source."
	break
fi


#Start transfer keys to other computer.
read -p "Please input your transfer computer passwd : " MY_Password

for j in `cat $PWD/transfer.txt`
do
{
	/usr/bin/expect <<EOF
	swapn scp /root/.ssh/authorized_keys $j:/root/.ssh/authorized_keys
	expect {
		"yes/no"	{ send "yes\r" ; exp_continue }
		"password:"	{ send "$MY_Password\r" ; exp_continue }
	}
EOF
}&
done
wait
echo "Transfer end $(date +%Y-%m-%d_%k:%M:%S)" >> /var/log/transfer_key.log
