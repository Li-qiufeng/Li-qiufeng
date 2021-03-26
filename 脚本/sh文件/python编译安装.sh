#scp python.sh 10.11.59.$i:/root/   //首先把脚本放到需要安装python的主机上，以便执行脚本

#如果用wget下载国外python.org网站上的源码包网速慢或不可访问的话，也可以用之前事先下载好的包


yum -y groupinstall "Development Tools"
yum -y install  zlib-devel bzip2-devel openssl-devel  sqlite-devel readline-devel  libffi-devel
#wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tar.xz
#if [ $? -ne 0 ];then
#    echo "网络故障，下载失败"
#    exit
#fi
tar -xf Python-3.7.6.tar.xz 
cd  Python-3.7.6/
sed -ri 's/^#readline/readline/' Modules/Setup.dist
sed -ri 's/^#(SSL=)/\1/' Modules/Setup.dist
sed -ri 's/^#(_ssl)/\1/' Modules/Setup.dist 
sed -ri 's/^#([\t]*-DUSE)/\1/' Modules/Setup.dist 
sed -ri 's/^#([\t]*-L\$\(SSL\))/\1/' Modules/Setup.dist
 ./configure --enable-shared && make -j 2 && make install
cmd1='export LD_LIBRARY_PATH='
cmd2='$LD_LIBRARY_PATH:/usr/local/lib'
file="/etc/profile.d/python3_lib.sh"
echo "${cmd1}${cmd2}" >$file
path="/usr/local/lib"
file2="/etc/ld.so.conf.d/python3.conf"
echo ${path} > $file2
ldconfig

#使配置好的环境信息生效 source /etc/profile  //因为source不能在脚本中执行   
#测试
#python3 -V
#pip3 -V
#配置使用本地的源安装第三方模块
# mkdir ~/.pip
#echo '[global]' >> ~/.pip/pip.conf
#c1="index-url=https://"
#c2="mirrors.aliyun.com/pypi/simple"
#echo "${c1}${c2}" >> ~/.pip/pip.conf
#pip3  install ipython

