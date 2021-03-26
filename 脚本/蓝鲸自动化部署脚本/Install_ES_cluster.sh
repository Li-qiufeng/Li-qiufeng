#!/bin/bash

#!/bin/sh
#
####################################################
# SCRIPT DIR : /opt/software/Install_ES_cluster.sh
#SCRIPT NAME : Install_ES_cluster.sh
#     AUTHOR : CanwayIT
#CREATE DATE : Mon Oct 26 14:00:00 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_ES_cluster.sh
#   FUNCTION : Install ElasticSearch (6.4.2) for Gaoji
#
####################################################
#   MODIFIER : CanwayIT
#MODIFY DATE : Med Oct 26 14:00:00 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the ElasticSearch														  
#              2)The script access permissions are 755
#
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C

#DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99                     # Define the return code when error
typeset -r softdir="/opt/software"
typeset -r modudir="/opt/module"
typeset -r jdkdir="${modudir}/jdk1.8.0_171"
typeset -r esdir="${modudir}/elasticsearch-6.4.2"
typeset -r nodejsdir="${modudir}/node-v8.11.3-linux-x64"
typeset -r es_cname="elk-es-clus01"
typeset -r repo_url="http://172.17.0.30/CentOS-YUM/Pub/Package"
typeset -r npm_registry="http://172.17.0.30:8081/repository/nodejs/"
typeset -r file_nodejs="node-v8.11.3-linux-x64.tar"
typeset -r file_jdk="jdk-8u171-linux-x64.tar.gz"
typeset -r file_es="elasticsearch-6.4.2.tar.gz"

typeset -r url_jdk="${repo_url}/${file_jdk}"
typeset -r url_es="${repo_url}/${file_es}"
typeset -r url_nodejs="${repo_url}/${file_nodejs}"
typeset -r confdir="${esdir}/config"
typeset -r datadir="/elk"
typeset -r logfile="/tmp/install_es_cluster.log"

#DEFINED DISPLAY COLOUR
typeset -r timestamp=$(date +%Y%m%d-%H%M%S)
typeset -r red="[$timestamp]\033[1m\033[31m[ERROR]"
typeset -r green="[$timestamp]\033[1m\033[32m[INFO]"
typeset -r yellow="[$timestamp]\033[1m\033[33m[WARNING]"
typeset -r offc="\033[0m\n"

#DEFINED VAR END

#####-----RECEIVE.CLUSTER-IP-----#####
MASTER_IP="172.17.0.61"
SLAVE1_IP="172.17.0.62"
SLAVE2_IP="172.17.0.63"
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

#Check es group&user exit or not.
Check_Group(){
  grep "^es:" /etc/group &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tGroup es not exist! Creating...\n"
    groupadd es
  else 
    printf "\t${yellow}Group es exist!${offc}"
  fi
}
Check_User(){
  id es &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tUser es not exist! Creating...\n"
    useradd -g es es
  else 
    printf "\t${yellow}User es exist!${offc}"
  fi
}

#Check directory.
InitDirs(){
  list="${modudir} ${softdir} ${datadir}"
  for i in $list;
  do
    if  [ ! -d $i ];then
        printf "\tDirectory $i not exist!\n"
        mkdir -p $i
        printf "\t$i create successfully!\n"
    fi
  done
}

Check_Repo(){
  yum clean all >>/dev/null
  packages=`yum repolist | awk -F: '/repolist:/{print $2}' | sed 's/,//'`
  if [[ ${packages} -eq 0 ]];then
    printf "\t${red}Unreachable path!!!  Please check your repo path.${offc}"
	return ${FAILED}
  fi
}
Install_Basepackages(){
  pack_list="gcc-c++ gcc coreutils zlib-devel openssl openssl-devel wget vim git"
  yum -y install $pack_list
}

# Get JDK&ES Package
Get_Package(){
  cd ${softdir}
  wget -O ${file_jdk} ${url_jdk} ; wget -O ${file_es} ${url_es} ; wget -O ${file_nodejs} ${url_nodejs}
  if [[ $? -ne 0 ]];then
    printf "\t${red}Package download failed. Please check your network.${offc}"
    return ${FAILED}
  fi
  
# uncompress JDK & ES Package
  tar -xf ${file_jdk} -C ${modudir}
  tar -xf ${file_es} -C ${modudir}
  tar -xf ${file_nodejs} -C ${modudir}
  chown -R es:es ${esdir}
  chown -R es:es ${datadir}
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

# set environment
Set_Env(){
  local user_envfile=/home/es/.bashrc
  cat >> ${user_envfile} << EOF
JAVA_HOME=${jdkdir}
ES_HOME=${esdir}
NODEJS_HOME=${nodejsdir}
PATH=\$JAVA_HOME/bin:\$ES_HOME/bin:\$NODEJS_HOME/bin:\$PATH
export JAVA_HOME ES_HOME NODEJS_HOME PATH
EOF
  source ${user_envfile}
  local sys_envfile=/etc/profile.d/elk.sh
  cat >> ${sys_envfile} << EOF
JAVA_HOME=${jdkdir}
ES_HOME=${esdir}
NODEJS_HOME=${nodejsdir}
PATH=\$JAVA_HOME/bin:\$ES_HOME/bin:\$NODEJS_HOME/bin:\$PATH
export JAVA_HOME ES_HOME NODEJS_HOME PATH
EOF
  source ${sys_envfile}
  echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
  sysctl -p
  echo "
* soft nofile 65536
* hard nofile 131072
es soft nproc 4096
es hard nproc 4096" >> /etc/security/limits.conf
  ulimit -n 65536
#  echo "registry = ${npm_registry}" >>/root/.npmrc
#  echo "registry = ${npm_registry}" >>/home/es/.npmrc
}

# Generator configrue
Set_Cnf(){
  export local_ip=$(GetLanIp | head -1)
  cd ${confdir}
  node_name="${es_cname}-node01"
  if [ "${local_ip}" == "${SLAVE1_IP}" ];then
    node_name="${es_cname}-node02"
  elif [ "${local_ip}" == "${SLAVE2_IP}" ];then
    node_name="${es_cname}-node03"
  fi
  temp_cnf="
cluster.name: ${es_cname}
node.name: ${node_name}
node.master: true
node.data: true
path.data: /elk/es/data
path.logs: /elk/es/logs
path.repo: [\"/elk/es_backup\"]
network.host: ${local_ip}
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: [\"${MASTER_IP}:9300\",\"${SLAVE1_IP}:9300\",\"${SLAVE2_IP}:9300\"]
discovery.zen.minimum_master_nodes: 1
bootstrap.memory_lock: false
bootstrap.system_call_filter: false
http.cors.enabled: true
http.cors.allow-origin: \"*\""
 echo "${temp_cnf}" >> elasticsearch.yml
}

Change_Jvm_Mem(){
  cd ${confdir}
  sed -i "s/-Xms1g/-Xms256m/g" jvm.options
  sed -i "s/-Xmx1g/-Xmx256m/g" jvm.options
}

# staring es 
Start_Es(){
  su es -c "${esdir}/bin/elasticsearch -d"
}

Check_Status(){
  es_status=/tmp/es.status.tmp
  for i in `seq 15`
  do
    rm -f ${es_status}
    sleep 5
    curl -s -o ${es_status} http://${local_ip}:9200
	if [ ! -s ${es_status} ]; then
	  echo "Try again. $i"
	else
	  return ${SUCCESS}
	fi
  done
  return ${FAILED}
}

#Install elasticsearch-head
Install_EsHead(){
    npm init -f
    npm config set registry ${npm_registry}
    cd ${confdir}
	git clone http://172.17.0.39/sauser/elasticsearch-head.git
    cd ${confdir}/elasticsearch-head
	sed -i "/port: 9100/a      hostname: '*'," Gruntfile.js
	sed -i "/localhost/s/localhost/${local_ip}/" _site/app.js
	npm update
	npm install -g npm
    npm install -g grunt-cli
	npm install phantomjs-prebuilt@2.1.16 --ignore-scripts
	npm install
    grunt server &
}

# The main function of the script
TaskMain(){
  typeset -i iRc_T=0
  printf "It is checking whether the yumrepo ready or not ...\n"
  Check_Repo
  Install_Basepackages
  printf "${green}The repo&basepackages all ready!${offc}"

  printf "It is initiazating user&directories ...\n"
  InitDirs
  Check_Group
  Check_User
  printf "${green}The directories user&initiazating completed!${offc}"
  
  printf "It is getting JDK&ES packages ...\n"
  Get_Package
  printf "${green}The package-files uncomp completed!${offc}"
  
  printf "It is setting user&sys env ...\n"
  Set_Env
  printf "${green}Environment set completed!${offc}"

  printf "It is setting config files ...\n"
  Set_Cnf
  Change_Jvm_Mem
  printf "${green}The config files set completed!${offc}"
  
  printf "Start es service...\n"
  Start_Es
  Check_Status;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}ElasticSearch start Failed.${offc}"
    return ${FAILED}
  fi
  Install_EsHead
}

# The execution body of the script
fifofile=/tmp/${RANDOM}.fifo
mkfifo $fifofile
cat $fifofile | tee -a $logfile &
exec 1>$fifofile
exec 2>&1
printf "[$timestamp][INFO]The script is being executed.\n"
printf "[$timestamp][INFO] Start installing ElasticSearch...\n"
  TaskMain;rc=$?
  if [ ${rc} -ne 0 ] ;then
    printf "${red} Failed to install ElasticSearch.${offc}"
        ScriptUsage
  else
    printf "${green}[INFO] Install and start ElasticSearch Completed.${offc}"
  fi
printf "[$timestamp]\033[1m\033[7m[INFO]The script execution ends.\033[0m\n"
printf "\015\n"
rm -f $fifofile
exit ${rc}

