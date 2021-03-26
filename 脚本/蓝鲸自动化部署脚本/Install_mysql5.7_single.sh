#!/bin/bash

#!/bin/sh
#
####################################################
# SCRIPT DIR : /opt/software/Install_mysql5.7_single.sh
#SCRIPT NAME : Install_mysql5.7_single.sh
#     AUTHOR : CanwayIT
#CREATE DATE : Med Sep 26 14:00:00 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_mysql5.7_single.sh
#   FUNCTION : Install MySQL Database (5.7.21) for Gaoji
#
####################################################
#   MODIFIER : CanwayIT
#MODIFY DATE : Med Sep 26 14:00:00 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)Input password for dbuser(root)
#              2)The script access permissions are 755
#
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C

#DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99                     # Define the return code when error
typeset -r NOT_ARGS=200                 # Define the return code when not specifies any argument for the method
typeset -i rc=1                         # Define the variable for return code
typeset -r softwaredir='/opt/software'
typeset -r basedir='/usr/share/mysql'
typeset -r datadir='/data/3306/data'
typeset -r configdir="/etc/3306"
typeset -r mysqluser='mysql'
typeset -r mysqlgroup='mysql'
typeset -r defaults_file="${configdir}/my.cnf"
typeset -r defaults_file_link='/etc/my.cnf'
#typeset -r mysqlfile_url="https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.21-1.el7.x86_64.rpm-bundle.tar"
typeset -r yumrepo_file1="http://172.17.0.30/CentOS-YUM/Pub/YumRepoFile/CentOS7/Mysql.repo"
#typeset -r yumrepo_file2="http://172.17.0.30/CentOS-YUM/Pub/YumRepoFile/CentOS7/Mysql.repo"

#DEFINED DISPLAY COLOUR
typeset -r red="\033[1m\033[31m"
typeset -r green="\033[1m\033[32m"
typeset -r yellow="\033[1m\033[33m"
typeset -r offc="\033[0m\n"

#DEFINED VAR END


#####-----PASSWORD-----#####
DEFAULT_PASSWD="1qaz@WSX"
#####-----PASSWORD-----#####

#Confirm the parameters
Confirm_Para(){
  para1=${1:-""}
  para2=${2:-""}
  if [[ "para1" == "-h" ]]; then
    ScriptUsage
  elif [[ "para1" == "-p" && "para2" != "" ]]; then
	DEFAULT_PASSWD="$2"
  fi
}

# load common script

#Purpose :
#    Print the format used to create user. Used to call the user 
#    creation method when the parameter is wrong.
#
ScriptUsage(){
  printf "Usage: sh $0 PASSWD\n"
  printf "\t-p:\t\tInput password for db'user root\n"
  printf "\t-h:\t\tPrint Usage for the script.\n"
  printf "For example:\n"
  printf "\tsh $0 -p 123456\n"
  printf "\tsh $0 -h\n"
  exit
}


#Check mysql group&user exit or not.
Check_Group(){
  grep ${mysqlgroup} /etc/group &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tGroup ${mysqlgroup} not exist! Creating...\n"
    groupadd -g 2049 ${mysqlgroup}
  else 
    printf "\t${yellow}Group ${mysqlgroup} exist!${offc}"
  fi
}
Check_User(){
  id ${mysqluser} &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tUser ${mysqluser} not exist! Creating...\n"
    useradd -r -u 2049 -g ${mysqlgroup} -s /bin/false ${mysqluser}
  else 
    printf "\t${yellow}User ${mysqluser} exist!${offc}"
  fi
}

#Check yum packages exit or not & Install base packages.
Install_Basepackages(){
  pack_list="gcc-c++ ncurses-devel cmake make perl gcc autoconf automake zlib libxml libgcrypt libtool bison perl libaio net-tool perl-Data-Dumper perl-JSON perl-Time-HiRes"
  yum -y install $pack_list
}
Check_Repo(){
  Temp_repo_file="/etc/yum.repos.d/${yumrepo_file1##*/}"
  wget -O ${Temp_repo_file} ${yumrepo_file1} 
  yum clean all >>/dev/null
  packages=`yum repolist | awk -F: '/repolist:/{print $2}' | sed 's/,//'`
  if [[ ${packages} -eq 0 ]];then
    printf "\t${red}Unreachable path!!!  Please check your repo path.${offc}"
	return ${FAILED}
  else 
    printf "\tThe repo path ok. Install basepackages...\n"
  fi
}

#Check directory.
InitDirs(){
  list="${basedir} ${datadir} ${configdir}"
  for i in $list;
  do
    if  [ ! -d $i ];then
        printf "\tDirectory $i not exist!\n"
        mkdir -p $i
        printf "\t$i create successfully!\n"
    fi
    chown -R ${mysqlgroup}:${mysqluser} $i
  done
  systemctl stop mysqld &>/dev/null
  rm -rf ${datadir}/*
}

SetMycnf(){                                    
  printf "
[client]
port                        =  3306
socket                      =  /tmp/mysql.sock 
default-character-set       =  utf8mb4  
 
[mysql]
no-auto-rehash  
 
[mysqld]  
user                       =  mysql
port                       =  3306
#basedir                    =  /usr/share/mysql  
datadir                    =  /data/3306/data 
socket                     =  /tmp/mysql.sock  
character-set-server       =  utf8mb4
log-error                  =  /data/3306/data/mysqld.err
pid-file                   =  /data/3306/data/mysqld.pid  
#skip-locking
skip-name-resolve          
skip-networking  
open_files_limit           = 1024
back_log                   = 384  
max_connections            = 1000 
max_connect_errors         = 800  
wait_timeout               = 1814400 
#table_cache                = 614K  
external-locking           = FALSE  
max_allowed_packet         = 16M  
sort_buffer_size           = 1M  
join_buffer_size           = 8M 
thread_cache_size          = 64  
query_cache_size           = 64M 
query_cache_limit          = 2M  
query_cache_min_res_unit   = 2k  
#default_table_type         = InnoDB  
thread_stack               = 22K  
# transaction_isolation    = READ COMMITTED
tmp_table_size             = 64M  
max_heap_table_size        = 64M  
table_open_cache           = 1024
long_query_time            = 2  
#log_long_format  
slow_query_log_file        = /data/3306/data/slow.log
log-bin                    = /data/3306/data/mysql-bin  
relay-log                  = /data/3306/data/relay-bin  
relay-log-info-file        = /data/3306/data/relay-log.info  
binlog_cache_size          = 4M  
max_binlog_cache_size      = 8M  
max_binlog_size            = 1G  
expire_logs_days           = 60  
key_buffer_size            = 22M  
read_buffer_size           = 8M  
read_rnd_buffer_size       = 16M
lower_case_table_names     = 1  
server-id                  = 111  

#innodb_additional_mem_pool_size  = 4M 
innodb_buffer_pool_size          = 64M  
innodb_data_file_path            = ibdata1:128M:autoextend  
innodb_thread_concurrency        = 8  
innodb_flush_log_at_trx_commit   = 1  
innodb_log_buffer_size           = 4M  
innodb_log_file_size             = 64M  
innodb_log_files_in_group        = 3  
innodb_lock_wait_timeout         = 30  
innodb_file_per_table            = 1  
innodb-flush-method				 =O_DIRECT
innodb_print_all_deadlocks		 =1
innodb_rollback_on_timeout	     =1

[mysqldump]
quick
max_allowed_packet               = 2M
  " > ${defaults_file}
  
  mv -f /etc/my.cnf /etc/my.cnf.bak
  chown ${mysqlgroup}:${mysqluser} ${defaults_file}
  ln -s ${defaults_file} /etc/my.cnf
}
  
Intall_Mysql(){
  old_pack=`rpm -qa |grep -E 'mysql|mariadb'`
  for i in ${old_pack}
  do
    rpm -e --nodeps ${i}
  done
  yum -y install mysql-server
  if [[ $? -ne 0 ]];then
    printf "\t${red}Cannot find mysql-server soft package!${offc}"
    return ${ERROR}
  fi
}

#initialize the mysqldb
Init_Mysql(){
  systemctl stop mysqld &>/dev/null
  rm -rf ${datadir}/*
#mysql 5.7
  mysqld --initialize-insecure --user=${mysqluser} --datadir=${datadir}
  chown -R ${mysqlgroup}:${mysqluser} ${datadir}
  systemctl start mysqld &>/dev/null
  if [[ $? -ne 0 ]];then
    return ${FAILED}
  else
    return ${SUCCESS}
  fi
}

#start the service
SetService(){
  systemctl start mysqld &>/dev/null
  systemctl status mysqld &>/dev/null
  if [[ $? -ne 0 ]];then
    return ${FAILED}
  else
    return ${SUCCESS}
  fi
  source /etc/profile
}

#change the default password
Change_Passwd(){
  #init_passwd=`grep 'root@localhost' /var/log/mysqld.log |awk -F: '{print $4}' |cut -c2-`
  mysql -N -e "alter user 'root'@'localhost' identified by '${DEFAULT_PASSWD}'"
  if [ $? -eq 0 ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi
}

#check status of the instace
Check_Instance(){
  SQL_RESULT_G=`mysql -uroot -p${DEFAULT_PASSWD} --skip-column-names -e "select 1 from dual" 2>/dev/null`
  if [ "$SQL_RESULT_G" == "1" ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi   
}
  
# The main function of the script
TaskMain(){
  typeset -i iRc_T=0
  printf "It is checking whether the user&yumrepo ready or not ...\n"
  Check_Group
  Check_User
  Check_Repo
  Install_Basepackages
  printf "${green}The user&repo all ready!${offc}"

  printf "It is initiazating directories ...\n"
  InitDirs
  printf "${green}The directories initiazating successful!${offc}"
  
  printf "It is installing mysql database ...\n"
  Intall_Mysql
  printf "${green}The mysql database install successful!${offc}"
  
  printf "It is setting mysql service ...\n"
  SetService;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Mysql service start failed!${offc}"
   return ${FAILED}
  fi
  printf "${green}Mysql service start successful!${offc}"
    
  printf "It is setting config files ...\n"
  SetMycnf
  printf "${green}The config files set successful!${offc}"
  
  printf "It is initiazating database ...\n"
  Init_Mysql;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}DB initiazate failed!${offc}"
   return ${FAILED}
  fi
  printf "${green}DB initiazate successful!${offc}"

  printf "It is changing password...\n"
  Change_Passwd;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Mysql password change failed!${offc}"
   return ${FAILED}
  fi
  printf "${green}Password change successful!${offc}"
  
  printf "It is checking whether the instance normall or not ...\n"
  Check_Instance;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Mysql instance start failed!${offc}"
   return ${FAILED}
  fi
  printf "${green}The instance is ready!${offc}"
}

# The execution body of the script
Confirm_Para
printf "The script is being executed.\n"
printf "[INFO] Start installing mysql ...\n"
  TaskMain $@;rc=$?
  if [ ${rc} -ne 0 ] ;then
    printf "${red}[ERROR] Failed to install mysql.${offc}"
        ScriptUsage
  else
    printf "${green}[INFO] Install and start mysql Completed.${offc}"
  fi
printf "\033[1m\033[7mThe script execution ends.\033[0m\n"
exit ${rc}