#！/bin/bash 
#
####################################################
#SCRIPT NAME : Install_Oracle_CentOS.sh
#     AUTHOR : luoyinsheng
#CREATE DATE : Thu Nov 15 11:28:01 CST 2018
#   PLATFORM : CentOS 
#      USAGE : sh Install_Oracle_CentOS.sh
#   FUNCTION : Install Oracle for Gaoji
####################################################
#   MODIFIER : luoyinsheng
#MODIFY DATE : Thu Nov 15 11:28:01 CST 2018
#    VERSION : V 1.0
#DESCRIPTION : This script implements the following requirements :
#              1)This script is used to automate the installation of the Oracle													  
#              2)The script access permissions are 755
####################################################
export LC_ALL=C                  #Set the LANG and all environment variable beginning with LC_ to C
# DEFINED VAR START
typeset -r SUCCESS=0                    # Define the return code when successful
typeset -r WARNING=1                    # Define the return code when an exception occurs
typeset -r FAILED=2                     # Define the return code when failed
typeset -r ERROR=99                     # Define the return code when error
# GET OS VERSION
typeset -r RELEASEVER=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
# ORACLE BASE ENV
typeset -r HOSTNAME="oracle"
typeset -r ORACLE_VERSION="12102"
typeset -r ORACLE_BASE="/oracle/u01/app"
typeset -r ORACLE_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/db_1"
typeset -r ORACLE_INVERTORY="/oracle/u01/inventory"
typeset -r ORACLE_DATA="/data/oradata"
typeset -r ORACLE_RECOVERY="/oracle/u01/flash_recovery_area"
typeset -r ORACLE_SID="orcl"
# ORACLE USER&GROUP
typeset -r install_group="oinstall"
typeset -r dba_group="dba"
typeset -r oper_group="oper"
typeset -r install_user="oracle"
typeset -r install_user_pwd="oracle"
# SYSTEM BASE
typeset -r ipadd=$(ip addr | grep global | awk '{print $2}' | cut -d '/' -f1)
typeset -r hostname="oracle"
typeset -r modudir="/usr/local"
typeset -r jdk_version="jdk-8u171"
typeset -r jdkdir="${modudir}/java"
# INSTALL PACKAGE
typeset -r repo_url="http://172.17.0.30/CentOS-YUM/Pub/Package"
typeset -r file_jdk="${jdk_version}-linux-x64.tar.gz"
typeset -r file_oracle1="linux_amd64_${ORACLE_VERSION}_oracle_database_1of2.zip"
typeset -r file_oracle2="linux_amd64_${ORACLE_VERSION}_oracle_database_2of2.zip"
typeset -r url_jdk="${repo_url}/${file_jdk}"
typeset -r url_oracle1="${repo_url}/${file_oracle1}"
typeset -r url_oracle2="${repo_url}/${file_oracle2}"
#DEFINED DISPLAY COLOUR
typeset -r timestamp=$(date +%Y%m%d-%H%M%S)
typeset -r red="[$timestamp]\033[1m\033[31m[ERROR]"
typeset -r green="[$timestamp]\033[1m\033[32m[INFO]"
typeset -r yellow="[$timestamp]\033[1m\033[33m[WARNING]"
typeset -r offc="\033[0m\n"
# stop selinux
Stop_Selinux(){
local selinux_conf="/etc/selinux/config"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' ${selinux_conf}
setenforce 0
}
# centos stop firewalld
Stop_Firewalld6(){
service iptables stop
chkconfig iptables 
}
Stop_Firewalld7(){
systemctl stop firewalld
systemctl disabled firewalld
}
# Install dependency packages
Install_packages(){
yum -y install binutils compat-libstdc++ compat-libstdc++-33 elfutils-libelf-devel gcc gcc-c++ glibc-devel glibc-headers ksh libaio-devel libstdc++-devel make sysstat unixODBC-devel binutils-* compat-libstdc++* elfutils-libelf* glibc* gcc-* libaio* libgcc* libstdc++* make* sysstat* unixODBC* wget unzip
}
# Install JDK
Install_Jdk(){
cd ${modudir}/src
wget ${repo_url}/${file_jdk}
tar -xf ${file_jdk} -C ${modudir} && ln -s ${modudir}/jdk1* ${jdkdir}/java
cat >> /etc/profile << EOF
export JAVA_HOME=${jdkdir}
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
}
#Set hosts & hostname
Set_hosts_hostname6(){
hostname ${hostname}
echo "NETWORKING=yes" > /etc/sysconfig/network
echo "HOSTNAME=${hostname}" >>/etc/sysconfig/network
echo "${ipadd} ${hostname}" >>/etc/hosts
}
Set_hosts_hostname7(){
hostnamectl --static set-hostname ${hostname}
echo "${ipadd} ${hostname}" >>/etc/hosts
}
#Check oracle group exit or not.
Check_Group(){
egrep "${install_group}" /etc/group >/dev/null
if [ $? -eq 0 ];then
        echo "this ${install_group} group is exits"
else
        groupadd ${install_group}
fi
egrep "${dba_group}" /etc/group >/dev/null
if [ $? -eq 0 ];then
        echo "this ${dba_group} group is exits"
else
        groupadd ${dba_group}
fi
egrep "${oper_group}" /etc/group >/dev/null
if [ $? -eq 0 ];then
        echo "this ${oper_group} group is exits"
else
        groupadd ${oper_group}
fi
}
#Check oracle user exit or not.
Check_User(){
egrep "$install_user" /etc/passwd >/dev/null
if [ $? -eq 0 ];then
        echo "this ${install_user} user is exits"
else
        useradd -g ${install_group} -G ${dba_group},${oper_group} ${install_user}
        echo "${install_user_pwd}" | passwd --stdin ${install_user}
fi
}
#Check directory.
InitDirs(){
  list="${modudir} ${ORACLE_BASE} ${ORACLE_INVERTORY} ${ORACLE_DATA} ${ORACLE_RECOVERY} ${ORACLE_HOME}"
  for i in $list;
  do
    if  [ ! -d $i ];then
        printf "\tDirectory $i not exist!\n"
        mkdir -p $i
        printf "\t$i create successfully!\n"
    fi
  done
  
  chown -R ${install_user}:${install_group} /oracle/
  chmod -R 775 /oracle/
  chown -R ${install_user}:${install_group} /data/
  chmod -R 775 /data/
}
# Set system sysctl
Set_Sysctl(){
local sysctl_conf="/etc/sysctl.conf"
sed -i 's/^fs.file-max/#&/g' ${sysctl_conf}
sed -i 's/^kernel.sem/#&/g' ${sysctl_conf}
sed -i 's/^kernel.shmmni/#&/g' ${sysctl_conf}
sed -i 's/^kernel.shmall/#&/g' ${sysctl_conf}
sed -i 's/^kernel.shmmax/#&/g' ${sysctl_conf}
sed -i 's/^net.core.rmem_default/#&/g' ${sysctl_conf}
sed -i 's/^net.core.rmem_max/#&/g' ${sysctl_conf}
sed -i 's/^net.core.wmem_default/#&/g' ${sysctl_conf}
sed -i 's/^net.core.wmem_max/#&/g' ${sysctl_conf}
sed -i 's/^fs.aio-max-nr/#&/g' ${sysctl_conf}
sed -i 's/^net.ipv4.ip_local_port_range/#&/g' ${sysctl_conf}
echo "fs.file-max = 6815744" >>${sysctl_conf}
echo "kernel.sem = 250 32000 100 128" >>${sysctl_conf}
echo "kernel.shmmni = 4096">>${sysctl_conf}
echo "kernel.shmall = 1073741824">>${sysctl_conf}
echo "kernel.shmmax = 4398046511104">>${sysctl_conf}
echo "net.core.rmem_default = 262144">>${sysctl_conf}
echo "net.core.rmem_max = 4194304" >>${sysctl_conf}
echo "net.core.wmem_default = 262144">>${sysctl_conf}
echo "net.core.wmem_max = 1048576">>${sysctl_conf}
echo "fs.aio-max-nr = 1048576">>${sysctl_conf}
echo "net.ipv4.ip_local_port_range = 9000 65500">>${sysctl_conf}
sysctl -p >>/dev/null
}
# Set user limits
Set_Limits(){
local limits_conf="/etc/security/limits.conf"
local login_pam="/etc/pam.d/login"
echo "${install_user}   soft   nofile   1024"  >>${limits_conf}
echo "${install_user}   hard   nofile   65536" >>${limits_conf}
echo "${install_user}   soft   nproc    2047"  >>${limits_conf}
echo "${install_user}   hard   nproc    16384" >>${limits_conf}
echo "${install_user}   soft   stack    10240" >>${limits_conf}
echo "${install_user}   hard   stack    32768" >>${limits_conf}
echo "session    required    /lib64/security/pam_limits.so">>${login_pam}
echo "session    required    pam_limits.so" >>${login_pam}
}
# Set environment variable
Set_Env(){
# For root user
echo "if [ \$USER = "${install_user}" ]; then
        if [ \$SHELL = "/bin/ksh" ]; then
                ulimit -p 16384
                ulimit -n 65536
        else
                ulimit -u 16384 -n 65536
		fi
                umask 022
fi">>/etc/profile
source /etc/profile

# For Oracle user
echo "export ORACLE_BASE=${ORACLE_BASE}" >>/home/${install_user}/.bash_profile
echo "export ORACLE_HOME=${ORACLE_HOME}" >>/home/${install_user}/.bash_profile
echo "export ORACLE_SID=${ORACLE_SID}" >>/home/${install_user}/.bash_profile
echo "export ORACLE_TERM=xterm" >>/home/${install_user}/.bash_profile
echo "export NLS_DATE_FORMAT=\"DD-MON-YYYY HH24:MI:SS\"" >>/home/${install_user}/.bash_profile
echo "export TNS_ADMIN=$ORACLE_HOME/network/admin" >>/home/${install_user}/.bash_profile
echo "export NLS_LANG=\"American_america.AL32UTF8\"" >>/home/${install_user}/.bash_profile
echo "export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin:/usr/bin:/bin:/usr/local/bin" >>/home/${install_user}/.bash_profile
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$ORACLE_HOME/oracm/lib:/lib:/usr/lib:/usr/local/lib" >>/home/${install_user}/.bash_profile
echo "export ORA_NLS11=$ORACLE_HOME/nls/data" >>/home/${install_user}/.bash_profile
echo "export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib" >>/home/${install_user}/.bash_profile
echo "export THEADS_FLAG=native" >>/home/${install_user}/.bash_profile
echo "export TEMP=/tmp" >>/home/${install_user}/.bash_profile
echo "export TMPDIR=/tmp" >>/home/${install_user}/.bash_profile
echo "umask 022" >>/home/${install_user}/.bash_profile
echo "if [ \$USER = "${install_user}" ]; then
        if [ \$SHELL = "/bin/ksh" ]; then
                ulimit -p 16384
                ulimit -n 65536
        else
                ulimit -u 16384 -n 65536
        fi
                umask 022
fi">>/home/${install_user}/.bash_profile
source /home/${install_user}/.bash_profile
}
# Download oracle install file
Get_Package(){
su - oracle <<EOF
cd ${ORACLE_BASE};
wget ${repo_url}/${file_oracle1};
wget ${repo_url}/${file_oracle2};
unzip ${file_oracle1} &> /dev/null;
unzip ${file_oracle2} &> /dev/null;
rm -f ${file_oracle1} ${file_oracle2};
exit;
EOF
}
# Set db_install.rsp file
Set_Install(){
install=`sed -n '/oracle.install.option/p' ${ORACLE_BASE}/database/response/db_install.rsp`
hostname1=`sed -n '/ORACLE_HOSTNAME/p' ${ORACLE_BASE}/database/response/db_install.rsp`
group_name=`sed -n '/UNIX_GROUP_NAME/p' ${ORACLE_BASE}/database/response/db_install.rsp`
inventory=`sed -n '/INVENTORY_LOCATION/p' ${ORACLE_BASE}/database/response/db_install.rsp`
languages=`sed -n '/^SELECTED_LANGUAGES=en$/p' ${ORACLE_BASE}/database/response/db_install.rsp`
oracle_home=`sed -n '/ORACLE_HOME/p' ${ORACLE_BASE}/database/response/db_install.rsp`
oracle_base=`sed -n '/ORACLE_BASE/p' ${ORACLE_BASE}/database/response/db_install.rsp`
InstallEdition=`sed -n '/oracle.install.db.InstallEdition/p' ${ORACLE_BASE}/database/response/db_install.rsp`
dba_group1=`sed -n '/oracle.install.db.DBA_GROUP/p' ${ORACLE_BASE}/database/response/db_install.rsp`
oper_group1=`sed -n '/oracle.install.db.OPER_GROUP/p' ${ORACLE_BASE}/database/response/db_install.rsp`
updates=`sed -n '/^DECLINE_SECURITY_UPDATES=$/p' ${ORACLE_BASE}/database/response/db_install.rsp`
sed -i 's/oracle.install.db.BACKUPDBA_GROUP=/oracle.install.db.BACKUPDBA_GROUP=dba/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.DGDBA_GROUP=/oracle.install.db.DGDBA_GROUP=dba/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.KMDBA_GROUP=/oracle.install.db.KMDBA_GROUP=dba/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.globalDBName=/oracle.install.db.config.starterdb.globalDBName='"${ORACLE_SID}"'/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.SID=/oracle.install.db.config.starterdb.SID='"${ORACLE_SID}"'/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.type=/oracle.install.db.config.starterdb.type=GENERAL_PURPOSE/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.password.ALL=/oracle.install.db.config.starterdb.password.ALL='"${install_user_pwd}"'/g' ${ORACLE_BASE}/database/response/db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.memoryLimit=/oracle.install.db.config.starterdb.memoryLimit=81920/g' ${ORACLE_BASE}/database/response/db_install.rsp

if [ "$install" = "oracle.install.option=" ]
 then
   sed -i "s#oracle.install.option=#oracle.install.option=INSTALL_DB_SWONLY#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$install parameter don't update!"
fi
if [ "$hostname1" = "ORACLE_HOSTNAME=" ]
 then
 sed -i "s#ORACLE_HOSTNAME=#ORACLE_HOSTNAME=${HOSTNAME}#g" ${ORACLE_BASE}/database/response/db_install.rsp
  echo "parameter update succeeful!"
 else
   echo "$hostname1 parameter don't update!"
fi

if [ "$group_name" = "UNIX_GROUP_NAME=" ]
 then
  sed -i "s#UNIX_GROUP_NAME=#UNIX_GROUP_NAME=${install_group}#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$group_name parameter don't update!"
fi

if [ "$inventory" = "INVENTORY_LOCATION=" ]
 then
  sed -i "s#INVENTORY_LOCATION=#INVENTORY_LOCATION=${ORACLE_INVERTORY}#g" ${ORACLE_BASE}/database/response/db_install.rsp
 echo "parameter update succeeful!"
 else
   echo "$inventory parameter don't update!"
fi


if [ "$languages" = "SELECTED_LANGUAGES=en" ]
 then
  sed -i "s#SELECTED_LANGUAGES=en#SELECTED_LANGUAGES=en,zh_CN#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$languages parameter don't update!"
fi

if [ "$oracle_home" = "ORACLE_HOME=" ]
 then
 sed -i "s#ORACLE_HOME=#ORACLE_HOME=${ORACLE_HOME}#g" ${ORACLE_BASE}/database/response/db_install.rsp
  echo "parameter update succeeful!"
 else
   echo "$oracle_home parameter don't update!"
fi


if [ "$oracle_base" = "ORACLE_BASE=" ]
 then
  sed -i "s#ORACLE_BASE=#ORACLE_BASE=${ORACLE_BASE}#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$oracle_base parameter don't update!"
fi


if [ "$InstallEdition" = "oracle.install.db.InstallEdition=" ]
 then
  sed -i "s#oracle.install.db.InstallEdition=#oracle.install.db.InstallEdition=EE#g" ${ORACLE_BASE}/database/response/db_install.rsp
 echo "parameter update succeeful!"
 else
   echo "$InstallEdition parameter don't update!"
fi


if [ "$dba_group1" = "oracle.install.db.DBA_GROUP=" ]
 then
   sed -i "s#oracle.install.db.DBA_GROUP=#oracle.install.db.DBA_GROUP=dba#g" ${ORACLE_BASE}/database/response/db_install.rsp
    echo "parameter update succeeful!"
 else
   echo "$dba_group1 parameter don't update!"
fi


if [ "$oper_group1" = "oracle.install.db.OPER_GROUP=" ]
 then
  sed -i "s#oracle.install.db.OPER_GROUP=#oracle.install.db.OPER_GROUP=oper#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$oper_group1 parameter don't update!"
fi


if [ "$updates" = "DECLINE_SECURITY_UPDATES=" ]
 then
  sed -i "s#DECLINE_SECURITY_UPDATES=#DECLINE_SECURITY_UPDATES=true#g" ${ORACLE_BASE}/database/response/db_install.rsp
   echo "parameter update succeeful!"
 else
   echo "$updates parameter don't update!"
fi
}
#Install oracle
Install_Oracle(){
su - oracle <<EOF
cd ${ORACLE_BASE}/database;
./runInstaller -silent -responseFile ${ORACLE_BASE}/database/response/db_install.rsp -ignorePrereq;
EOF
echo "300 seconds..."
sleep 300
sh ${ORACLE_INVERTORY}/orainstRoot.sh
sh ${ORACLE_HOME}/root.sh
}
# Install netca
Install_netca(){
su - oracle <<EOF
cd ${ORACLE_HOME}/bin/;
./netca /silent /responseFile ${ORACLE_BASE}/database/response/netca.rsp;
EOF
}
# Set dbca.rsp file
Set_Dbca(){
sed -i 's/^GDBNAME.*$/GDBNAME = '"${ORACLE_SID}"'/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/^SID.*$/SID = '"${ORACLE_SID}"'/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#DATAFILEDESTINATION =/DATAFILEDESTINATION =/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's#DATAFILEDESTINATION =#DATAFILEDESTINATION = '"${ORACLE_DATA}"'#g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#RECOVERYAREADESTINATION=/RECOVERYAREADESTINATION=/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's#RECOVERYAREADESTINATION=#RECOVERYAREADESTINATION= '"${ORACLE_RECOVERY}"'#g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#CHARACTERSET = "US7ASCII"/CHARACTERSET = "AL32UTF8"/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#SYSPASSWORD = "password"/SYSPASSWORD = '"${install_user_pwd}"'/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#SYSTEMPASSWORD = "password"/SYSTEMPASSWORD = '"${install_user_pwd}"'/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#SYSDBAPASSWORD = "password"/SYSDBAPASSWORD = '"${install_user_pwd}"'/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#EMEXPRESSPORT = ""/EMEXPRESSPORT = 5500/g' ${ORACLE_BASE}/database/response/dbca.rsp
sed -i 's/#TOTALMEMORY = "800"/TOTALMEMORY = "3096"/g' ${ORACLE_BASE}/database/response/dbca.rsp
}
# Install oracle db
Install_db(){
su - oracle << EOF
cd ${ORACLE_HOME}/bin/;
./dbca -silent -responseFile ${ORACLE_BASE}/database/response/dbca.rsp;
${install_user_pwd}
${install_user_pwd}
EOF
}
# Set Start up
Set_Start(){
sed -i 's#ORACLE_HOME_LISTNER=$1#ORACLE_HOME_LISTNER='"${ORACLE_HOME}"'#g' ${ORACLE_HOME}/bin/dbstart
sed -i 's#ORACLE_HOME_LISTNER=$1#ORACLE_HOME_LISTNER='"${ORACLE_HOME}"'#g' ${ORACLE_HOME}/bin/dbshut

# Set service start up
sed -i 's#'"${ORACLE_SID}"':'"${ORACLE_HOME}"':N#'"${ORACLE_SID}"':'"${ORACLE_HOME}"':Y#g' /etc/oratab
echo "su - oracle -c \"${ORACLE_HOME}\"/bin/lsnrctl start" >> /etc/rc.d/rc.local
echo "su - oracle -c \"${ORACLE_HOME}\"/bin/dbstart" >> /etc/rc.d/rc.local
touch /var/lock/subsys/oracle
cat >> /etc/init.d/oracle<<-EOF
#!/usr/bin/env bash
# oracle: Start/Stop Oracle Database
# chkconfig: 345 90 10
# description: The Oracle Database is an Object-Relational Database Management System.

. /etc/rc.d/init.d/functions
LOCKFILE=/var/lock/subsys/oracle
ORACLE_HOME=${ORACLE_HOME}
ORACLE_USER=${install_user}
case "$1" in
'start')
   if [ -f $LOCKFILE ]; then
      echo $0 already running.
      exit 1
   fi
   echo -n $"Starting Oracle Database:"
   su - $ORACLE_USER -c "$ORACLE_HOME/bin/lsnrctl start"
   su - $ORACLE_USER -c "$ORACLE_HOME/bin/dbstart $ORACLE_HOME"
   #su - $ORACLE_USER -c "$ORACLE_HOME/bin/emctl start dbconsole"
   touch $LOCKFILE
   ;;
'stop')
   if [ ! -f $LOCKFILE ]; then
      echo $0 already stopping.
      exit 1
   fi
   echo -n $"Stopping Oracle Database:"
   su - $ORACLE_USER -c "$ORACLE_HOME/bin/lsnrctl stop"
   su - $ORACLE_USER -c "$ORACLE_HOME/bin/dbshut"
   #su - $ORACLE_USER -c "$ORACLE_HOME/bin/emctl stop dbconsole"
   rm -f $LOCKFILE
   ;;
'restart')
   $0 stop
   $0 start
   ;;
'status')
   if [ -f $LOCKFILE ]; then
      echo $0 started.
      else
      echo $0 stopped.
   fi
   ;;
*)
   echo "Usage: $0 [start|stop|status]"
   exit 1
esac
exit 0
EOF
chmod 755 /etc/init.d/oracle
if [ ${RELEASEVER} == '6Server' ];then
   chkconfig oracle on
fi
if [ ${RELEASEVER} == 7 ];then
   systemctl daemon-reload
   systemctl enable oracle.service
fi
}
# Verify status and process
Check_Status(){
netstat -tulnp | grep 1521
ps -ef | grep ora_ | grep -v grep
su - oracle << EOF
cd ${ORACLE_HOME}/bin/;
./lsnrctl status
EOF
if [ $? -eq 0 ];then
printf "${green}install oracle succeeful!${offc}"
fi
}
# Install Task queue
TaskMain(){
  printf "It is checking whether the base&basepackages ready or not ...\n"
  Stop_Selinux
  if [ ${RELEASEVER} == '6Server' ];then
     Stop_Firewalld6
  fi
  if [ ${RELEASEVER} == 7 ];then
     Stop_Firewalld7
  fi
  Install_packages
  Install_Jdk
  if [ ${RELEASEVER} == '6Server' ];then
     Set_hosts_hostname6
  fi
  if [ ${RELEASEVER} == 7 ];then
     Set_hosts_hostname7
  fi
  printf "${green}The base&basepackages all ready!${offc}"

  printf "It is initiazating user&directories ...\n"
  Check_Group
  Check_User
  InitDirs
  printf "${green}The directories user&initiazating completed!${offc}"
  
  printf "It is getting JDK&ES packages ...\n"
  Set_Sysctl
  Set_Limits
  Set_Env
  Get_Package
  printf "${green}The package-files uncomp completed!${offc}"
  
  printf "It is install oracle ...\n"
  Set_Install
  Install_Oracle
  Install_netca
  Set_Dbca
  Install_db
  Set_Start
  printf "${green}install oracle!${offc}"
  
  printf "Start Oracle Status...\n"
  Check_Status
}
TaskMain