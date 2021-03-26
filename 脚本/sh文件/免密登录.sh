auto_keygen (){
    /usr/bin/expect<<EOF

    set timeout 30

    spawn   ssh-keygen

    expect     {

        ".ssh/id_rsa)"       { send    "\n";  exp_continue }
        "Overwrite (y/n)?"   { send    "y\n"; exp_continue }
        "no passphrase):"    { send    "\n";  exp_continue }
        "again:"             { send    "\n";  exp_continue }
    }

EOF
}
auto_keygen 

send_key () {
pwd=123
/usr/bin/expect <<EOF
set timeout 30
spawn ssh-copy-id root@10.11.59.219
expect {
"yes/no" { send "yes\n"; exp_continue }
"password:" { send "${pwd}\n"; exp_continue } 
}
expect eof
EOF
}
send_key

pub_key_file=$HOME/.ssh/id_rsa.pub

if [ ! -f ${pub_key_file} ];then
    auto_keygen
fi
#for ip in $(cat ./ips.txt)
#do
#   send_key $ip
#done
