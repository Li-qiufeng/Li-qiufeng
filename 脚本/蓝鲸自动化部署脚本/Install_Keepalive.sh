#！/bin/bash
#
####################################################
# SCRIPT DIR : /opt/software/Install_Keepalived.sh
#SCRIPT NAME : Install_Keepalived.sh
#     AUTHOR : luoyinsheng
#CREATE DATE : Thu Nov 15 11:28:01 CST 2018
#   PLATFORM : Linux
#      USAGE : sh Install_Keepalived.sh
#   FUNCTION : Install Keepalived for Gaoji
#
####################################################
#   MODIFIER : luoyinsheng
#MODIFY DATE : Thu Nov 15 11:28:01 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the tomcat											
#              2)The script access permissions are 755
if [ $# -ne 3 ];then
  echo "usage: sh $0 \$1 \$2 \$3"
  echo "\$1 is router id"
  echo "\$2 is vip"
  echo "\$3 is check application name 'myql@mysqlrouter@nginx...'"
  echo "If you make a mistake, Please follow the tips to find reason."
  exit
fi
#
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C
#DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99
 
#DEFINED DISPLAY COLOUR
typeset -r timestamp=$(date +%Y%m%d-%H%M%S)
typeset -r red="[$timestamp]\033[1m\033[31m[ERROR]"
typeset -r green="[$timestamp]\033[1m\033[32m[INFO]"
typeset -r yellow="[$timestamp]\033[1m\033[33m[WARNING]"
typeset -r offc="\033[0m\n"

#KEEPALIVED VAR START
typeset -r router_id=$1
typeset -r vip=$2
typeset -r check_app=$3
typeset -r master_ip='172.17.0.61'
typeset -r backup_ip='172.17.0.62'
typeset -r local_ip=$(ip addr | grep global | awk '{print $2}' | cut -d '/' -f1)
typeset -r model='BACKUP'
typeset -r priotiry_master=100
typeset -r priotiry_backup=90
typeset -r interface='eth0'
typeset -r netmask=24
typeset -r hostname=$(hostname)
typeset -r keepalived_home='/etc/keepalived'

ScriptUsage(){
  echo "usage: sh $0 \$1 \$2 \$3"
  echo "\$1 is router id"
  echo "\$2 is vip"
  echo "\$3 is check application name 'myql@mysqlrouter@nginx...'"
  echo "If you make a mistake, Please follow the tips to find reason."
}

Install_Keepalived(){
which keepalived
if [ $? -ne 0 ]; then
    yum -y install keepalived
fi
}

Set_Config(){
cat >$keepalived_home/keepalived.conf<<-EOF
! Configuration File for keepalived

global_defs {
   notification_email {
   root@localhost
   }
   notification_email_from root@local.domain
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id ${hostname}
}
vrrp_script check_script {
EOF

if [ $check_app == 'mysql' ];then
cat >>$keepalived_home/keepalived.conf<<-EOF
   script "/etc/keepalived/check_mysql.sh"
EOF
elif [ $check_app == 'mysqlrouter' ];then
cat >>$keepalived_home/keepalived.conf<<-EOF
   script "/etc/keepalived/check_mysqlrouter.sh"
EOF
elif [ $check_app == 'nginx' ];then
cat >>$keepalived_home/keepalived.conf<<-EOF
   script "/etc/keepalived/check_nginx.sh"
EOF
fi

cat >>$keepalived_home/keepalived.conf<<-EOF
   interval 2
   weight -2
}
vrrp_instance VI_1 {
    state ${model}
    interface ${interface}
    virtual_router_id ${router_id}
EOF

if [ ${local_ip} == ${master_ip} ]; then
cat >>$keepalived_home/keepalived.conf<<-EOF
    nopreempt
    priority ${priotiry_master}
    unicast_src_ip ${master_ip}
    unicast_peer {
        ${backup_ip}
    }
EOF
elif [ ${local_ip} == ${backup_ip} ];then
cat >>$keepalived_home/keepalived.conf<<-EOF
    priority ${priotiry_backup}
    unicast_src_ip ${backup_ip}
    unicast_peer {
        ${master_ip}
    }
EOF
fi

cat >>$keepalived_home/keepalived.conf<<-EOF
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    track_script {
        check_script
    }
    virtual_ipaddress {
    ${vip}/${netmask}
    }
}
EOF
}

Set_Check_Script(){
if [ $check_app == 'mysqlrouter' ];then
cat >$keepalived_home/check_mysqlrouter.sh<<-"EOF"
#!/bin/bash
for i in {3306..3315}
do
line=$(ss -anput |grep :$i |awk -F" " '/LISTEN/{print $(NF-2)}' | cut -d':' -f2)
echo $line
if [ $line == $i ];
    then
       echo "mysqlrouter Running "  
    else
       systemctl stop keepalived
    fi
done
EOF
chmod +x $keepalived_home/check_mysqlrouter.sh
fi

if [ $check_app == 'mysql' ];then
cat >$keepalived_home/check_mysql.sh<<-"EOF"
#!bin/bash
which mysql
if [ $? -ne 0 ]; then
   MYSQL=/usr/local/3306/mysql-5.7.21/bin/mysql
else
   MYSQL=/bin/mysql
fi
MYSQL_HOST=localhost
MYSQL_USER=keepalive
MYSQL_PASSWORD=J8D9zXm1u4Kl
$MYSQL -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -e "show databases;" >/dev/null 2>&1
if [ $? -eq 0 ]
then
    echo " mysql login successfully "  
else
    systemctl stop keepalived
fi
EOF
chmod +x $keepalived_home/check_mysql.sh
fi

if [ $check_app == 'nginx' ];then
cat >$keepalived_home/check_nginx.sh<<-"EOF"
#!/bin/bash
port=80
which nmap
if [ $? -ne 0 ]; then
   yum -y install nmap
fi
nmap localhost -p $port | grep "$port/tcp open"
if [ $? -ne 0 ];then
   systemctl stop keepalived
fi
EOF
chmod +x $keepalived_home/check_nginx.sh
fi
}

Start_Keepalived(){
systemctl enable keepalived
systemctl start keepalived
}

Check_Status(){
systemctl status keepalived
if [ $? -ne 0 ]; then
	return ${FAILED}
else
	return ${SUCCESS}
fi
}

TaskMain(){
  typeset -i iRc_T=0
  printf "It is install keepalive ...\n"
  Install_Keepalived
  printf "${green}The  keepalive initiazating completed!${offc}"
  
  printf "It is set keepalive config ...\n"
  Set_Config
  printf "${green}The keepalive config completed!${offc}"
  
  printf "It is Set check script config ...\n"
  Set_Check_Script
  printf "${green}The check script completed!${offc}"
  
  printf "Start keepalive service...\n"
  Start_Keepalived
  Check_Status;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}keepalived start Failed.${offc}"
    return ${FAILED}
  fi
}
# The execution body of the script
TaskMain $@;rc=$?
if [ ${rc} -ne 0 ] ;then
  printf "${red}[ERROR] Failed to install keepalive.${offc}"
      ScriptUsage
else
  printf "${green}[INFO] Install and start keepalive Completed.${offc}"
fi
