#!/bin/bash

#!/bin/sh
#
####################################################
# SCRIPT DIR : /opt/software/Install_RocketMQ_cluster.sh
#SCRIPT NAME : Install_RocketMQ_cluster.sh
#     AUTHOR : CanwayIT
#CREATE DATE : Mon Oct 08 14:00:00 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_RocketMQ_cluster.sh
#   FUNCTION : Install RocketMQ (4.2) for Gaoji
#
####################################################
#   MODIFIER : CanwayIT
#MODIFY DATE : Med Sep 26 14:00:00 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the RocketMQ
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
typeset -r mqdir="/opt/rocketmq"
typeset -r jdkdir="/opt/jdk"
typeset -r mavendir="/opt/maven"
typeset -r nameServerPort=9876
typeset brokerAPort=10911
typeset brokerBPort=11911
typeset brokerA_sPort=10921
typeset brokerB_sPort=11921
typeset -r url_mq="http://172.17.0.30/CentOS-YUM/Pub/Package/rocketmq-all-4.2.0-source-release.zip"
typeset -r url_jdk="http://172.17.0.30/CentOS-YUM/Pub/Package/jdk-8u171-linux-x64.tar.gz"
typeset -r url_maven="http://172.17.0.30/CentOS-YUM/Pub/Package/apache-maven-3.5.4-bin.tar.gz"
typeset -r url_maven_xml="http://172.17.0.30/CentOS-YUM/Pub/Maven/settings.xml"
typeset -r file_maven="${softdir}/${url_maven##*/}"
typeset -r file_mq="${softdir}/${url_mq##*/}"
typeset -r file_jdk="${softdir}/${url_jdk##*/}"

#DEFINED DISPLAY COLOUR
typeset -r red="\033[1m\033[31m[ERROR]"
typeset -r green="\033[1m\033[32m[INFO]"
typeset -r yellow="\033[1m\033[33m[WARNING]"
typeset -r offc="\033[0m\n"

#DEFINED VAR END

#####-----RECEIVE.CLUSTER-IP-----#####
MASTER_IP="1.1.1.1"
SLAVE1_IP="1.1.1.2"
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
InitDirs(){
  list="${mqdir} ${softdir} ${jdkdir} ${mavendir}"
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
  pack_list="gcc-c++ ncurses-devel cmake make perl gcc autoconf automake zlib libxml libgcrypt libtool bison libaio \
   net-tool readline readline-devel zip unzip zlib-devel openssl openssl-devel wget vim"
  yum -y install $pack_list
}

# Get JDK & MQ Package
Get_Package(){
  wget -O ${file_mq} ${url_mq} && wget -O ${file_jdk} ${url_jdk} && wget -O ${file_maven} ${url_maven}
  if [[ $? -ne 0 ]];then
    printf "\t${red}JDK & MQ Package download failed. Please check your network.${offc}"
    return ${FAILED}
  fi
  
# uncompress JDK & MQ Package
  tar -xf ${file_jdk} -C ${jdkdir}
  tar -xf ${file_maven} -C ${mavendir}
  unzip ${file_mq} -d ${mqdir}
}

# Make && make install MQ
Make_Mq(){
  source ~/.bash_profile
  cd ${mqdir}/rocketmq-all-4.2.0
  rm -fv ${MAVEN_HOME}/conf/settings.xml
  wget -O ${MAVEN_HOME}/conf/settings.xml ${url_maven_xml}
  #cp ${softdir}/settings.xml ${MAVEN_HOME}/conf/
  mvn -Prelease-all -DskipTests clean install -U
  cp -r  ${mqdir}/rocketmq-all-4.2.0/distribution/target/apache-rocketmq ${mqdir}/
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
  user_envfile=~/.bash_profile
  cat >> ${user_envfile} << EOF
JAVA_HOME=${jdkdir}/jdk1.8.0_171
MAVEN_HOME=${mavendir}/apache-maven-3.5.4
ROCKETMQ_HOME=${mqdir}/apache-rocketmq
PATH=\$JAVA_HOME/bin:\$MAVEN_HOME/bin:\$ROCKETMQ_HOME/bin:\$PATH
export JAVA_HOME MAVEN_HOME ROCKETMQ_HOME PATH
EOF
  source ${user_envfile}
}
# define service environment
Service_Env(){
  source ~/.bash_profile
  export local_ip=$(GetLanIp | head -1)
# Base variable
  export clusterName="DefaultCluster"
  export localHostIP=${local_ip}
  export commandPath="${ROCKETMQ_HOME}/bin"
  export launchScriptPath="${ROCKETMQ_HOME}/sbin"
  export configDir="${ROCKETMQ_HOME}/conf/cluster"
  export Adir=/data/broker-a
  export Bdir=/data/broker-b-s
  export logDir=/tmp
# NameServer variable
  export nameServerAddr="${MASTER_IP}:${nameServerPort};${SLAVE1_IP}:${nameServerPort}"
  export nameServerLaunchScript="${launchScriptPath}/startNameServer.sh"
# Broker-a variable
  export brokerAConfig="${configDir}/broker-a.properties"
  export brokerALaunchScript="${launchScriptPath}/start_broker-a.sh"
# Broker-b variable
  export brokerBConfig="${configDir}/broker-b-s.properties"
  export brokerBLaunchScript="${launchScriptPath}/start_broker-b-s.sh"
  if [ "${local_ip}" == "${SLAVE1_IP}" ];then
    export Adir=/data/broker-b
    export Bdir=/data/broker-a-s
	export brokerAConfig="${configDir}/broker-b.properties"
    export brokerALaunchScript="${launchScriptPath}/start_broker-b.sh"
    export brokerBConfig="${configDir}/broker-a-s.properties"
    export brokerBLaunchScript="${launchScriptPath}/start_broker-a-s.sh"
  fi
} 

isPid(){
  pidName=$1
  if pgrep -f ${pidName} &>/dev/null;then
    echo "${pidName} launched successful." > ${logDir}/${pidName}
  else
    echo "${pidName} launched failure." > ${logDir}/${pidName}
  fi
}

# Initialization processing
trimPrefixSpace(){
  fileName=$1
  sed -i "s/^\s\s\s\s//g" ${fileName}
}

# check service dir & file
Init_Serv_DF(){
  for i in "${configDir} ${launchScriptPath} ${Adir} ${Bdir}"
  do
    if [[ ! -d ${i} ]]; then
      mkdir -pv ${i}
    fi
  done
  for j in "${brokerAConfig} ${brokerBConfig} ${brokerALaunchScript} ${brokerBLaunchScript} ${nameServerLaunchScript}"
    do
    if [[ -f ${j} ]]; then
      rm -fv ${j} 
    fi
  done
}

# Generator configrue
Set_Cnf(){
  brokera="broker-a"
  brokerb="broker-b"
  if [ "${local_ip}" == "${SLAVE1_IP}" ];then
    brokera="broker-b"
	brokerb="broker-a"
    brokerAPort=${brokerBPort}
	brokerB_sPort=${brokerA_sPort}
  fi
  temp_cnf="
brokerClusterName=${clusterName}
deleteWhen=04
namesrvAddr=${nameServerAddr}
brokerIP1=${localHostIP}
fileReservedTime=48
flushDiskType=ASYNC_FLUSH"
# To Generate broker-a configure.
  echo "${temp_cnf}
brokerName=${brokera}
brokerId=0
listenPort=${brokerAPort}
storePathRootDir=${Adir}/store
storePathCommitLog=${Adir}/store/commitlog
brokerRole=SYNC_MASTER" >> ${brokerAConfig}
# To Generate broker-b configure.
  echo "${temp_cnf}
brokerName=${brokerb}
brokerId=1
listenPort=${brokerB_sPort}
storePathRootDir=${Bdir}/store
storePathCommitLog=${Bdir}/store/commitlog
brokerRole=SLAVE" >> ${brokerBConfig}
# processing configure space
  trimPrefixSpace ${brokerAConfig}
  trimPrefixSpace ${brokerBConfig}
}

# To generate a script for starting server
Generate_Scr(){
  temp_cnf="
#!/bin/bash
LanuchParam=start
helpLog(){
  echo \"usage: sh \$0 [start|stop|restart]\"
}
cd ${commandPath}
start(){
  setsid sh mqnamesrv -n "${nameServerAddr}" &
}
stop(){
  pkill -9 -f NamesrvStartup
}
restart(){
  stop
  sleep 1
  start
}
case \$@ in
start|START)
  start ;;
stop|STOP)
  stop ;;
restart|RESTART)
  restart ;;
*)
  helpLog
esac"
  echo "${temp_cnf}" > ${nameServerLaunchScript} 
  echo "${temp_cnf}" > ${brokerALaunchScript} 
  sed -i "/\&$/s/^/##/" ${brokerALaunchScript}
  sed -i "/^##/a  setsid sh mqbroker -c ${brokerAConfig} &" ${brokerALaunchScript}
  sed -i "s/NamesrvStartup/broker-a/g" ${brokerALaunchScript}
  echo "${temp_cnf}" > ${brokerBLaunchScript}
  sed -i "/\&$/s/^/##/" ${brokerBLaunchScript}
  sed -i "/^##/a  setsid sh mqbroker -c ${brokerBConfig} &" ${brokerBLaunchScript}
  sed -i "s/NamesrvStartup/broker-b/g" ${brokerBLaunchScript}

# processing configure space
  trimPrefixSpace ${nameServerLaunchScript}
  trimPrefixSpace ${brokerALaunchScript}
  trimPrefixSpace ${brokerBLaunchScript}
}

# change memory of the JAVA VM
Change_Jvm_Mem(){
  cd ${commandPath}
  sed -i "s/-Xms4g -Xmx4g -Xmn2g/-Xms256m -Xmx256m -Xmn256m/g" runserver.sh
  sed -i "s/-Xms8g -Xmx8g -Xmn4g/-Xms512m -Xmx512m -Xmn512m/g" runbroker.sh
}

Exec_Scr(){
# staring NameServer
  LanuchParam=start
  sh ${nameServerLaunchScript} ${LanuchParam} &
# starting broker-a
  sh ${brokerALaunchScript} ${LanuchParam} &
# staring broker-b
  sh ${brokerBLaunchScript} ${LanuchParam} &
}

Check_MqStatus(){
  sleep 5
  for i in "NamesrvStartup broker-a broker-b"
  do
    isPid ${i}
    cat /tmp/${i} | grep "failure";iRc_T=$?
    if [ ${iRc_T} -eq 0 ] ;then
      printf "${red} ${i} start failed!,please check.${offc}"
      return ${FAILED}
    fi
	cat /tmp/${i}
  done
}

# The main function of the script
TaskMain(){
  typeset -i iRc_T=0
  printf "[INFO]It is checking whether the yumrepo ready or not ...\n"
  Check_Repo
  Install_Basepackages
  printf "${green}The repo&basepackages all ready!${offc}"
  
  printf "[INFO]It is setting service env ...\n"
  User_Env
  Service_Env
  printf "${green}Environment set completed!${offc}"

  printf "[INFO]It is initiazating directories ...\n"
  InitDirs
  printf "${green}The directories initiazating completed!${offc}"
  
  printf "[INFO]It is getting JDK&RocketMQ packages ...\n"
  Get_Package
  printf "${green}The package-files uncomp completed!${offc}"

  printf "[INFO]It is make & install MQ ...\n"
  Make_Mq
  Init_Serv_DF;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Failed!,please check the scripts.${offc}"
   return ${FAILED}
  fi
  printf "${green}RocketMQ make install completed!${offc}"
    
  printf "[INFO]It is setting config files ...\n"
  Set_Cnf
  printf "${green}The config files set completed!${offc}"
  
  printf "[INFO]It is Generate service scripts ...\n"
  Generate_Scr
  #Change_Jvm_Mem
  printf "${green}Scripts generate successful!${offc}"
  
  printf "[INFO]It is executing scripts to start MQ service...\n"
  Exec_Scr;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}MQ failed!,please check the scripts of service${offc}"
   return ${FAILED}
  fi
  Check_MqStatus;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
   printf "${red}Start failed!,please check the service${offc}"
   return ${FAILED}
  fi
  printf "${green}The MQ service start successful!${offc}"
}

# The execution body of the script
printf "[INFO]The script is being executed.\n"
printf "[INFO] Start installing RocketMQ ...\n"
  TaskMain $@;rc=$?
  if [ ${rc} -ne 0 ] ;then
    printf "${red}  Failed to install RocketMQ.${offc}"
        ScriptUsage
  else
    printf "${green}[INFO] Install and start RocketMQ Completed.${offc}"
  fi
printf "\033[1m\033[7m[INFO]The script execution ends.\033[0m\n"
exit ${rc}




