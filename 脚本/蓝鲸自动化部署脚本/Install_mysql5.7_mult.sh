#!/bin/bash

#!/bin/sh
#
####################################################
# SCRIPT DIR : /opt/software/Install_mysql5.7_mult.sh
#SCRIPT NAME : Install_mysql5.7_mult.sh
#     AUTHOR : CanwayIT
#CREATE DATE : Med Sep 26 14:00:00 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_mysql5.7_mult.sh
#   FUNCTION : Install MySQL Database (5.7.21) for Gaoji
#
####################################################
#   MODIFIER : CanwayIT
#MODIFY DATE : Med Sep 26 14:00:00 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)Input password for dbuser(root)
#              2)Input the variables name and value you set(master/slave1/slave2)
#              3)The script access permissions are 755
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
typeset -r mysqlshell_url="https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.0.12-1.el7.x86_64.rpm"
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

#####-----RECEIVE.CLUSTER-IP-----#####
MASTER_IP="1.1.1.1"
SLAVE1_IP="1.1.1.2"
SLAVE2_IP="1.1.1.3"
#####-----END.CLUSTER-IP-----#####

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
  list="${softwaredir} ${basedir} ${datadir} ${configdir}"
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

#Get the local ip.
GetLanIp(){ 
    ip addr | awk -F'[ /]+' '/inet/{
               split($3, N, ".")
               if ($3 ~ /^192.168/) {
                   print $3
               }
               if (($3 ~ /^172/) && (N[2] >= 16) && (N[2] <= 31)) {
                   print $3
               }
               if ($3 ~ /^10\./) {
                   print $3
               }
          }';
    return $?
}

#Makesure local is master or slave1/slave2
Confirm_Local(){
  export local_ip=$(GetLanIp | head -1)
  for i in ${local_ip}
  do
    if [ "${i}" == "${MASTER_IP}" ]; then
	  printf "\t${yellow}The local will be ${red}MASTER${offc}"
	  return 10
	elif [ "${i}" == "${SLAVE1_IP}" ]; then
	  printf "\t${yellow}The local will be ${red}SLAVE1${offc}"
	  return 12
    elif [ "${i}" == "${SLAVE2_IP}" ]; then
	  printf "\t${yellow}The local will be ${red}SLAVE2${offc}"
	  return 14
    fi
	printf "\t${yellow}check your cluster_ip.${offc}"
    return ${WARNING}
  done
}

SetMycnf(){                                       
  printf "
[client]
port                        =  3306
socket                      =  /tmp/mysql.sock 
default-character-set       =  utf8mb4  
 
[mysql]
no-auto-rehash  

[mysqldump]
quick
max_allowed_packet         = 2M
 
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
server-id                  = 110  

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

Intall_Mysqlshell(){
  Temp_File_DB=${softwaredir}/${mysqlshell_url##*/}
  wget -O ${Temp_File_DB} ${mysqlshell_url}
  ls ${Temp_File_DB} &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\t${red}Cannot find mysqlshell soft package!${offc}"
    return ${ERROR}
  else
    cd ${softwaredir}
	rpm -ivh ${Temp_File_DB}
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
  systemctl restart mysqld &>/dev/null
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
  SQL_RESULT_I=`mysql -uroot -p${DEFAULT_PASSWD} --skip-column-names -e "select 1 from dual" 2>/dev/null`
  if [ "$SQL_RESULT_I" == "1" ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi   
}

AddMycnf_cluster(){
  Ip_segment="${local_ip%.*}.0/24"
  printf "
#for gtid
gtid_mode = ON
enforce_gtid_consistency = ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
binlog_checksum = NONE
log_slave_updates = ON

#for group replication
transaction_write_set_extraction = XXHASH64
loose-group_replication_group_name    = ce9be252-2b71-11e6-b8f4-00212889f823
loose-group_replication_start_on_boot = off
loose-group_replication_local_address = "${local_ip}:33061"
loose-group_replication_group_seeds       = "${MASTER_IP}:33061,${SLAVE1_IP}:33061,${SLAVE2_IP}:33061"
loose-group_replication_ip_whitelist      = "${Ip_segment},127.0.0.1/24"
loose-group_replication_bootstrap_group   = off
loose-group_replication_single_primary_mode = on
loose-group_replication_enforce_update_everywhere_checks = off" >> ${defaults_file}
}

AddRepl_Group(){
  mysql -uroot -p${DEFAULT_PASSWD} -N -e "
  set sql_log_bin=0;
  CREATE USER 'repl'@'%' IDENTIFIED WITH 'mysql_native_password' BY '1234278';
  grant select,replication slave,replication client on *.* to 'repl'@'%' ;
  flush privileges;
  set sql_log_bin=1;
  install plugin group_replication soname 'group_replication.so';
  CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='12342' FOR CHANNEL 'group_replication_recovery';
  "
  if [ $? -eq 0 ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi
}

Change_Master(){ 
  mysql -uroot -p${DEFAULT_PASSWD} -N -e "
  SET GLOBAL group_replication_bootstrap_group = ON;
  START GROUP_REPLICATION;
  set global group_replication_bootstrap_group = off;
  "
# use the SQL "select * from performance_schema.replication_group_members;" to check group_member.
  if [ $? -eq 0 ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi
}

Change_Slave1(){
  sed -i '/^server-id/s/110/112/' ${defaults_file_link}
  mysql -uroot -p${DEFAULT_PASSWD} -N -e "
  set global group_replication_allow_local_lower_version_join=ON;
  START GROUP_REPLICATION;
  "
  if [ $? -eq 0 ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi
}

Change_Slave2(){
  sed -i '/^server-id/s/110/114/' ${defaults_file_link}
  mysql -uroot -p${DEFAULT_PASSWD} -N -e "
  set global group_replication_allow_local_lower_version_join=ON;
  START GROUP_REPLICATION;
  "
  if [ $? -eq 0 ];then
    return ${SUCCESS}
  else
    return ${FAILED}
  fi
}

Exec_Master(){
  AddMycnf_cluster
  SetService;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Mysql service restart failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Mysql service restart successful!${offc}"
  
  AddRepl_Group;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_replication config add failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_replication config add successful!${offc}"
  
  Change_Master;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_master config failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_master config successful!${offc}"
  
  Intall_Mysqlshell;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    return ${FAILED}
  fi
  printf "${green}Mysqlshell install successful!${offc}"
}

Exec_Slave1(){
  AddMycnf_cluster
  SetService;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Mysql service restart failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Mysql service restart successful!${offc}"
  
  AddRepl_Group;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_replication config add failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_replication config add successful!${offc}"
  
  Change_Slave1;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_Slave1 config failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_Slave1 config successful!${offc}"
  
  Intall_Mysqlshell;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    return ${FAILED}
  fi
  printf "${green}Mysqlshell install successful!${offc}"
}

Exec_Slave2(){
  AddMycnf_cluster
  SetService;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Mysql service restart failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Mysql service restart successful!${offc}"
  
  AddRepl_Group;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_replication config add failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_replication config add successful!${offc}"
  
  Change_Slave2;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Group_Slave2 config failed!${offc}"
    return ${FAILED}
  fi
  printf "${green}Group_Slave2 config successful!${offc}"
  
  Intall_Mysqlshell;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    return ${FAILED}
  fi
  printf "${green}Mysqlshell install successful!${offc}"
}

Config_GroupRepl(){
  Confirm_Local;iRc_T=$?
  if [[ ${iRc_T} -eq 1 ]];then
    printf "${yellow}The local_ip isnot in cluster_ip!\n"
    printf "Already install single instance!${offc}"
	return ${WARNING}
  elif [[ ${iRc_T} -eq 10 ]]; then
    printf "It is exec change_group_repl_master ...\n"
	Exec_Master;iRc_S=$?
    if [[ ${iRc_S} -ne 0 ]]; then
      printf "${red}Exec change_group_repl_master failed!${offc}"
	  return ${FAILED}
    fi
    printf "${green}Exec change_group_repl_master successful${offc}"
  elif [[ ${iRc_T} -eq 12 ]]; then
    printf "It is exec change_group_repl_slave1 ...\n"
	Exec_Master;iRc_S=$?
    if [[ ${iRc_S} -ne 0 ]]; then
      printf "${red}Exec change_group_repl_slave1 failed!${offc}"
	  return ${FAILED}
    fi
    printf "${green}Exec change_group_repl_slave1 successful${offc}"
  elif [[ ${iRc_T} -eq 14 ]]; then
    printf "It is exec change_group_repl_slave2 ...\n"
	Exec_Master;iRc_S=$?
    if [[ ${iRc_S} -ne 0 ]]; then
      printf "${red}Exec change_group_repl_slave2 failed!${offc}"
	  return ${FAILED}
    fi
    printf "${green}Exec change_group_repl_slave2 successful${offc}"
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
  
  printf "It is Makesure local is master or slave...\n"
  Config_GroupRepl;iRc_T=$?
  if [ ${iRc_T} -eq 2 ] ;then
    printf "${red}The group_repl is failed!${offc}"
    return ${FAILED}
  elif [ ${iRc_T} -eq 1 ] ;then
    printf "${red}The group_repl isnot set!${offc}"
    return ${SUCCESS}
  fi
  printf "${green}The group_repl is successful!${offc}"
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