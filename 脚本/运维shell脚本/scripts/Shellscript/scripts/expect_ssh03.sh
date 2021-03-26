#!/usr/bin/expect
set ip [lindex $argv 0]
set user root
set password centos
set timeout 5

spawn ssh $user@$ip

expect {
	"yes/no" { send "yes\r"; exp_continue }
	"password:" { send "$password\r" };
} 
#interact
expect "#"
send "useradd yangyang\r"
send "pwd\r"
send "exit\r"
expect eof

