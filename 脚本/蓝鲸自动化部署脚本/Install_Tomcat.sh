#！/bin/bash 
#
####################################################
# SCRIPT DIR : /opt/software/Install_Tomcat.sh
#SCRIPT NAME : Install_Tomcat.sh
#     AUTHOR : luoyinsheng
#CREATE DATE : Thu Nov 15 11:28:01 CST 2018
#   PLATFORM : AIX/Linux
#      USAGE : sh Install_Tomcat.sh
#   FUNCTION : Install Tomcat (8.5.35) for Gaoji
#
####################################################
#   MODIFIER : luoyinsheng
#MODIFY DATE : Thu Nov 15 11:28:01 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the tomcat														  
#              2)The script access permissions are 755
#
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C
#DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99                     # Define the return code when error
typeset -r softdir="/usr/local/src"
typeset -r modudir="/usr/local"
typeset -r jdk_version="jdk-8u171"
typeset -r tomcat_version="8.5.35"
typeset -r daemon_version="1.1.0"
typeset -r jdkdir="${modudir}/java"
typeset -r tomcatdir="${modudir}/tomcat"
typeset -r daemondir="${modudir}/daemon"
typeset -r repo_url="http://172.17.0.30/CentOS-YUM/Pub/Package"
typeset -r file_jdk="${jdk_version}-linux-x64.tar.gz"
typeset -r file_tomcat="apache-tomcat-${tomcat_version}.tar.gz"
typeset -r file_daemon="commons-daemon-${daemon_version}-native-src.tar.gz"
typeset -r url_jdk="${repo_url}/${file_jdk}"
typeset -r url_tomcat="${repo_url}/${file_tomcat}"
typeset -r url_daemon="${repo_url}/${file_daemon}"
#DEFINED DISPLAY COLOUR
typeset -r timestamp=$(date +%Y%m%d-%H%M%S)
typeset -r red="[$timestamp]\033[1m\033[31m[ERROR]"
typeset -r green="[$timestamp]\033[1m\033[32m[INFO]"
typeset -r yellow="[$timestamp]\033[1m\033[33m[WARNING]"
typeset -r offc="\033[0m\n"
#Check directory.
InitDirs(){
  list="${modudir} ${softdir}"
  for i in $list;
  do
    if  [ ! -d $i ];then
        printf "\tDirectory $i not exist!\n"
        mkdir -p $i
        printf "\t$i create successfully!\n"
    fi
  done
}
#Check es group&user exit or not.
Check_Group(){
  grep "^tomcat:" /etc/group &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tGroup tomcat not exist! Creating...\n"
    groupadd tomcat
  else 
    printf "\t${yellow}Group tomcat	exist!${offc}"
  fi
}
Check_User(){
  id tomcat &>/dev/null
  if [[ $? -ne 0 ]];then
    printf "\tUser tomcat not exist! Creating...\n"
    useradd -g tomcat tomcat
  else 
    printf "\t${yellow}User tomcat exist!${offc}"
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
# Get JDK&Tomcat&daemon Package
Get_Package(){
  cd ${softdir}
  wget -O ${file_jdk} ${url_jdk} ; wget -O ${file_tomcat} ${url_tomcat} ; wget -O  ${file_daemon} ${url_daemon}
  if [[ $? -ne 0 ]];then
    printf "\t${red}Package download failed. Please check your network.${offc}"
    return ${FAILED}
  fi  
# uncompress JDK & Tomcat Package
  tar -xf ${file_jdk} -C ${modudir} && ln -s ${modudir}/jdk1* ${modudir}/java
  tar -xf ${file_tomcat} -C ${modudir} &>/dev/null && ln -s ${modudir}/apache-tomcat-* ${modudir}/tomcat
  tar -xf ${file_daemon} -C ${modudir} && ln -s ${modudir}/commons-daemon* ${modudir}/daemon
  chown -R tomcat:tomcat ${jdkdir}/
  chown -R tomcat:tomcat ${tomcatdir}/
  chown -R tomcat:tomcat ${daemondir}/
}
# Generator configrue
Install_Daemon(){
yum -y install gcc-c++ libstdc++-devel
cd ${daemondir}/unix && ./configure --with-java=${jdkdir} && make
cp ${daemondir}/unix/jsvc ${tomcatdir}/bin/
sed -i "91i\JAVA_HOME=${jdkdir}" ${tomcatdir}/bin/daemon.sh
cat > ${tomcatdir}/bin/setenv.sh <<-EOF
# add tomcat pid
CATALINA_PID="${tomcatdir}/tomcat.pid"
# add JAVA_HOME
JAVA_HOME=${jdkdir}
# add JAVA_OPTS
JAVA_OPTS="-server -Xms256M -Xmx512M -XX:MaxNewSize=256m"
EOF
chmod +x ${tomcatdir}/bin/setenv.sh
}
Set_Env(){
local sysrc_envfile=/etc/bashrc
cat >> ${sysrc_envfile} <<-EOF
JAVA_HOME=${jdkdir}
CATALINA_HOME=${tomcatdir}
PATH=\$JAVA_HOME/bin:\$PATH
export JAVA_HOME CATALINA_HOME PATH 
EOF
source ${sysrc_envfile}
local sys_envfile=/etc/profile
cat >> ${sys_envfile} <<-EOF
JAVA_HOME=${jdkdir}
CATALINA_HOME=${tomcatdir}
PATH=\$JAVA_HOME/bin:\$PATH
export JAVA_HOME CATALINA_HOME PATH 
EOF
source ${sys_envfile}
}
# Set system to manage tomcat management service
Sys_Tomcat(){
local tomcat_server=/etc/systemd/system/tomcat.service
cat > ${tomcat_server} <<-EOF
[Unit]
Description=Apache Tomcat
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=${tomcatdir}/tomcat.pid
Environment=JAVA_HOME=${modudir}/java
Environment=CATALINA_HOME=${modudir}/tomcat
ExecStart=${tomcatdir}/bin/daemon.sh start
ExecStop=${tomcatdir}/bin/daemon.sh stop
User=tomcat
Group=tomcat
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat
}
Check_Status(){
  export local_ip=$(GetLanIp | head -1)
  local tomcat_status=/tmp/tomcat.status.tmp
  for i in `seq 3`
  do
    rm -f ${tomcat_status}
    sleep 2
    curl -s -o ${tomcat_status} http://${local_ip}:8080
	if [ ! -s ${tomcat_status} ]; then
	  echo "Try again. $i"
	else
	  return ${SUCCESS}
	fi
  done
  return ${FAILED}
}
TaskMain(){
  typeset -i iRc_T=0
  printf "It is initiazating user&directories ...\n"
  InitDirs
  Check_Group
  Check_User
  printf "${green}The directories user&initiazating completed!${offc}"
  
  printf "It is getting JDK&Tomcat&daemon packages ...\n"
  Get_Package
  Install_Daemon
  printf "${green}The package-files uncomp completed!${offc}"
  
  printf "Start tomcat service...\n"
  Set_Env
  Sys_Tomcat
  Check_Status;iRc_T=$?
  if [ ${iRc_T} -ne 0 ] ;then
    printf "${red}Tomcat start Failed.${offc}"
    return ${FAILED}
  fi
}
# The execution body of the script
TaskMain $@;rc=$?
if [ ${rc} -ne 0 ] ;then
  printf "${red}[ERROR] Failed to install tomcat.${offc}"
      ScriptUsage
else
  printf "${green}[INFO] Install and start tomcat Completed.${offc}"
fi
  
