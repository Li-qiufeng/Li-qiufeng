#! /bin/bash
stty erase ^H
cat <<EOF
----------------------------------------------------------
+                 编译安装mysql服务V1.0                  +
----------------------------------------------------------
+                       注意事项                         +
+    请使用干净服务器使用本脚本 ，谢谢                   +
+    本脚本只支持mysql-boost-5.7.31此版本源码包          +
+    将脚本和mysql源码都放在/root/上，                   +
+    放错会出错, 按装不上，请按要求操作。                +
+    建议使用本脚本最低配置 1H2G                         +
----------------------------------------------------------
+                作者：大宝不胖，但是很壮                +
+                邮箱：db88788@163.com                   +
----------------------------------------------------------
+          A.确定服务器干净，并全新安装                  +
+          B.检查主机是否有数据库服务                    +
+          Q.退出                                        +
----------------------------------------------------------
EOF
read -p "请输入序号："  num
case $num in
A|a)
		echo "以确定本机环境干净，确认安装"
	sleep 1
		echo "正在准备编译软件"
	while :
	do
yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make cmake
		if [ $? -eq 0 ];then
		echo "编译软件准备完毕，开始下一步"
		break
		else
yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make cmake
		fi
		done
		echo "正在环境准备"
groupadd mysql
useradd -r -g mysql -s /bin/nologin mysql
	sleep 1
		echo "开始解压mysql源码包"
tar -vxzf /root/mysql-boost-5.7.31.tar.gz
	sleep 1
		echo "开始配置"
cd mysql-5.7.31
cmake . \
-DWITH_BOOST=boost/boost_1_59_0/ \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DSYSCONFDIR=/etc \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DINSTALL_MANDIR=/usr/share/man \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1
		if [ $? -eq 0 ];then
		echo "配置完成，开始下一步"
		else
		echo "配置出错，请手动检查"
	sleep 1
		exit 0
		fi
		echo "开始编译安装，时间有些长，请耐心等待。。。"
make && make install
		if [ $? -eq 0 ];then
		echo "编译安装完成，开始初始化"
		else
		echo "编译安装出错，请手动检测"
	sleep 1
		exit 0
		fi
cd /usr/local/mysql
mkdir mysql-files
chown -R mysql.mysql /usr/local/mysql
./bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data &>/root/mysql
csmm=`cat /root/mysql | awk 'NR==7''{print $11}'`
		echo "正在创建mysql配置文件"
echo "[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data" > /etc/my.cnf
		echo "添加环境变量"
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
echo "PATH=$PATH" >> /etc/profile
source /etc/profile
cp  /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig mysqld on
	sleep 1
		echo "开始启动mysql"
systemctl start mysqld
		if [ $? -eq 0 ];then
		echo "启动成功"
read -p "请输入新的密码必须是大小写数字结合：" xinmima
mysqladmin -u root -p$csmm password $xinmima
		echo "密码修改完毕，请使用"
<<EOF
-------------------------------------------------
+           数据库密码：$num                    +
+        systemctl 操作方式数据库               +
+    /usr/local/mysql是数据库的安装目录         +
+mysqladmin -u root -p源密码  password ‘新密码’ +
+ 如需重新安装数据库，请使用干净的机器再使用脚本+
-------------------------------------------------
+      有什么问题或是建议，请联系我             +
+          邮箱：db88788@163.com                +
-------------------------------------------------
EOF
		else
		echo "启动失败，请检查"
	sleep 1
		fi
;;
B|b)
		echo "开始检查"
systemctl status mysqld &>/dev/null
		if [ $? -eq 0 ];then
		echo "当前主机上有yum安装的数据库"
	sleep 1
cd /root/
sh bymysql.sh
		break
		else
		echo "没有yum安装的数据库服务"
	sleep 1
		exit 0
		fi
;;
Q|q)
		echo "正在退出，谢谢您的使用"
	sleep 2
		exit 0
;;
esac
