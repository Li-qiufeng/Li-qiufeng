#!/bin/bash

#!/bin/sh
#
####################################################
# SCRIPT DIR : /opt/software/Install_Redis_cluster.sh
#SCRIPT NAME : Install_Redis_cluster.sh
#     AUTHOR : CanwayIT
#CREATE DATE : Fri Oct 12 14:00:00 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_Redis_cluster.sh
#   FUNCTION : Install Redis repl (4.0) for Gaoji
#
####################################################
#   MODIFIER : CanwayIT
#MODIFY DATE : Med Sep 26 14:00:00 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the Redis
#!!!          2)The IP data must to be modified before running
#              3)The script access permissions are 755

#
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C

#DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99                     # Define the return code when error
typeset -i rc=1                         # Define the variable for return code
typeset -r softdir="/opt/software"
typeset -r redisgroup="redis"
typeset -r redisuser="redis"
typeset -r url_redis="http://172.17.0.30/CentOS-YUM/Pub/Package/redis-4.0.9.tar.gz"
typeset -r url_ruby="http://172.17.0.30/CentOS-YUM/Pub/Package/ruby-2.4.4.tar.gz"
typeset -r url_redis_gem="http://172.17.0.30/CentOS-YUM/Pub/Package/redis-4.0.1.gem"
typeset -r name_redis="${url_redis##*/}"
typeset -r name_ruby="${url_ruby##*/}"
typeset -r file_redis="${softdir}/${name_redis}"
typeset -r file_ruby="${softdir}/${name_ruby}"
typeset -r file_redis_gem="${softdir}/${url_redis_gem##*/}"
typeset -r ver_redis="${name_redis//.tar.gz/}"
typeset -r ver_ruby="${name_ruby//.tar.gz/}"
typeset -r port=6380
typeset -r port2=6381
typeset -r redisdir="/usr/local/${ver_redis}"
typeset -r confdir="/etc/redis/${port}"
typeset -r confdir2="/etc/redis/${port2}"
typeset -r datadir="/data/redis/${port}"
typeset -r datadir2="/data/redis/${port2}"
typeset -r rubydir="/usr/local/ruby"
typeset -r srcdir="/usr/local/src"

#DEFINED DISPLAY COLOUR
typeset -r red="\033[1m\033[31m"
typeset -r green="\033[1m\033[32m"
typeset -r yellow="\033[1m\033[33m"
typeset -r offc="\033[0m\n"

#DEFINED VAR END

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
  echo "usage: sh $0"
  echo "If you make a mistake, Please follow the tips to find reason."
  exit
}

#Check directory.
Check_Dirs(){
  list="${softdir} ${confdir} ${confdir2} ${datadir} ${datadir2} ${rubydir}"
  for i in $list;
  do
    if  [ ! -d $i ];then
        printf "\tDirectory $i not exist!\n"
        mkdir -p $i
        printf "\t$i create successfully!\n"
    fi
  done
}
Init_Dirs(){
  list2="${redisdir} ${confdir} ${confdir2} ${datadir} ${datadir2}"
  for i in $list2;
  do
    chown -R ${redisgroup}:${redisuser} ${i}
    chmod -R 744 ${i}
  done
}


#Check redis group&user exit or not.
Check_Group(){
  grep ${redisgroup} /etc/group &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tGroup ${redisgroup} not exist! Creating...\n"
    groupadd -g 505 ${redisgroup}
  else 
    printf "\t${yellow}Group ${redisgroup} exist!${offc}"
  fi
}
Check_User(){
  id ${redisuser} &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tUser ${redisuser} not exist! Creating...\n"
    useradd -u 505 -g ${redisgroup} ${redisuser}
  else 
    printf "\t${yellow}User ${redisuser} exist!${offc}"
  fi
}

Check_Repo(){
  #Temp_repo_file="/etc/yum.repos.d/${yumrepo_file1##*/}"
  #wget -O ${Temp_repo_file} ${yumrepo_file1} 
  yum clean all >>/dev/null
  packages=`yum repolist | awk -F: '/repolist:/{print $2}' | sed 's/,//'`
  if [[ ${packages} -eq 0 ]];then
    printf "\t${red}Unreachable path!!!  Please check your repo path.${offc}"
	return ${FAILED}
  fi
}
Install_Basepackages(){
  pack_list="gcc gcc-c++ libtool make cmake zlib zlib-devel readline readline-devel openssl openssl-devel wget vim \
   tkutil tk tkutil-develtk-devel ntp tcl"
  yum -y install $pack_list
}

#Get Ruby & Redis Package
Get_Package(){
  wget -O ${file_ruby} ${url_ruby} && wget -O ${file_redis_gem} ${url_redis_gem} && wget -O ${file_redis} ${url_redis} 
  if [[ $? -ne 0 ]];then
    printf "\t${red}Package-files download failed. Please check your network.${offc}"
	return ${FAILED}
  fi
  
# uncompress JDK & MQ Package
  tar -xf ${file_ruby} -C ${srcdir}
  tar -xf ${file_redis} -C /usr/local/
}

Make_Ruby(){
  cd ${srcdir}/${ver_ruby} || return ${FAILED}
  ./configure  --prefix=${rubydir}
  make && make install
  ln -s ${rubydir}/bin/ruby /usr/bin/ruby
  ln -s ${rubydir}/bin/gem /usr/bin/gem
}
Make_Redis(){
  cd ${redisdir} || return ${FAILED}
  make && make install
}

# update the ruby origin
Update_Ruby(){
  gem sources -r https://rubygems.org/
  gem sources -a http://172.17.0.30:8081/repository/rubygems/
  #gem sources -a https://gems.ruby-china.com/
  gem sources -l
  gem install ${file_redis_gem} || gem insatll redis
}

IsProc(){
  procname=$1
  if pgrep -f ${procname} &>/dev/null;then
    echo -e "$(date)\t${procname} launched successful." > /tmp/${procname}
  else
    echo "$(date)\t${procname} launched failure." > /tmp/${procname}
  fi
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

# set user environment
User_Env(){
  echo vm.overcommit_memory=1 >> /etc/sysctl.conf
  sysctl vm.overcommit_memory=1
  user_envfile=/etc/profile.d/redis.conf
  cat >> ${user_envfile} << EOF
REDIS_HOME=${redisdir}
PATH=\$REDIS_HOME/src:\$PATH
export REDIS_HOME PATH
EOF
  source ${user_envfile}
  user1_envfile=~/.bashrc
  cat >> ${user1_envfile} << EOF
REDIS_HOME=${redisdir}
PATH=\$REDIS_HOME/src:\$PATH
export REDIS_HOME PATH
EOF
  source ${user1_envfile}
}

# change redis config-file
Set_Cnf(){
  export local_ip=$(GetLanIp | head -1)
  cp -R ${redisdir}/redis.conf ${confdir}
  sed -i "/^bind/s/127.0.0.1/${local_ip}/" ${confdir}/redis.conf
  sed -i "/^port/s/6379/${port}/" ${confdir}/redis.conf
  sed -i "/^logfile/s#\"\"#\"${datadir}/redis.log\"#" ${confdir}/redis.conf
  sed -i "/^dir/s#./#${datadir}#" ${confdir}/redis.conf
  sed -i "/^pidfile/s#6379#${port}#" ${confdir}/redis.conf
  sed -i "/^# cluster-enable/a cluster-enabled yes" ${confdir}/redis.conf
  sed -i "/^# cluster-con/a cluster-config-file nodes-${port}.conf" ${confdir}/redis.conf
  sed -i "/^# cluster-node/a cluster-node-timeout 5000" ${confdir}/redis.conf

  cp -R ${redisdir}/redis.conf ${confdir2}
  sed -i "/^bind/s/127.0.0.1/${local_ip}/" ${confdir2}/redis.conf
  sed -i "/^port/s/6379/${port2}/" ${confdir2}/redis.conf
  sed -i "/^logfile/s#\"\"#\"${datadir2}/redis.log\"#" ${confdir2}/redis.conf
  sed -i "/^dir/s#./#${datadir2}#" ${confdir2}/redis.conf
  sed -i "/^pidfile/s#6379#${port2}#" ${confdir2}/redis.conf
  sed -i "/^# cluster-enable/a cluster-enabled yes" ${confdir2}/redis.conf
  sed -i "/^# cluster-con/a cluster-config-file nodes-${port2}.conf" ${confdir2}/redis.conf
  sed -i "/^# cluster-node/a cluster-node-timeout 5000" ${confdir2}/redis.conf
}

# start redis server
Start_Redis(){
  su - redis -c "setsid ${redisdir}/src/redis-server ${confdir}/redis.conf &"
  su - redis -c "setsid ${redisdir}/src/redis-server ${confdir2}/redis.conf &"
}
Start_Cluster(){
  if [ "${local_ip}" == "${MASTER_IP}" ]; then
    for i in `seq 3`
    do
      sleep 10
      ${redisdir}/src/redis-trib.rb create --replicas 1 ${MASTER_IP}:${port} ${MASTER_IP}:${port2} ${SLAVE1_IP}:${port} ${SLAVE1_IP}:${port2} ${SLAVE2_IP}:${port} ${SLAVE2_IP}:${port2} << EOF
yes
EOF
      iRc_T=$?
      if [ ${iRc_T} -eq 0 ] ;then
       printf "${green}redis-cluster create successful!${offc}"
       return ${SUCCESS}
      fi
    done
	printf "${red}redis-cluster create failed!${offc}"
	return ${FAILED}
  fi
}

# check redis status
Check_Status(){
  sleep 5
  IsProc redis-server
  cat /tmp/redis-server | grep "failure";iRc_T=$?
  if [ ${iRc_T} -eq 0 ] ;then
   printf "${red}redis-server start failed!,please check.${offc}"
   return ${FAILED}
  fi
}

# The main function of the script
TaskMain(){
  typeset -i iRc_T=0
  printf "It is checking whether the yumrepo ready or not ...\n"
  Check_Repo
  Install_Basepackages
  printf "${green}The repo&basepackages all ready!${offc}"

  printf "It is initiazating user&directories ...\n"
  Check_Dirs
  Check_Group
  Check_User
  printf "${green}The directories user&initiazating completed!${offc}"
  
  printf "It is getting Redis&ruby packages ...\n"
  Get_Package
  Make_Ruby
  Make_Redis
  printf "${green}The package-files uncomp completed!${offc}"
  
  printf "It is setting user env ...\n"
  User_Env
  printf "${green}Environment set completed!${offc}"
  
  printf "It is updating ruby...\n"
  Update_Ruby
  printf "${green}Ruby update successful!${offc}"

  printf "It is setting config files ...\n"
  Init_Dirs
  Set_Cnf
  printf "${green}The config files set completed!${offc}"
  
  printf "It is executing scripts to start redis service...\n"
  Start_Redis;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Redis-server failed!,please check the scripts of service${offc}"
   return ${FAILED}
  fi
  Check_Status
  Start_Cluster;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   return ${FAILED}
  fi
}

# The execution body of the script
printf "The script is being executed.\n"
printf "[INFO] Start installing Redis ...\n"
  TaskMain $@;rc=$?
  if [ ${rc} -ne 0 ] ;then
    printf "${red}[ERROR] Failed to install Redis.${offc}"
        ScriptUsage
  else
    printf "${green}[INFO] Install and start Redis Completed.${offc}"
  fi
printf "\033[1m\033[7mThe script execution ends.\033[0m\n"
exit ${rc}




