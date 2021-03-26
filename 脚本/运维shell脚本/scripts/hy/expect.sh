#!/usr/bin/expect
#必须和.kvm.sh在同一目录下	
	set ip [ lindex $argv 0 ]
	spawn ssh root@$ip
	expect {
		"(yes/no)?" { send "yes\r"; exp_continue }
		"password:" { send "centos\r" }
	}
	interact

