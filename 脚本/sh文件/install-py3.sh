yum groupinstall "Development Tools"
yum -y install  zlib-devel bzip2-devel openssl-devel  sqlite-devel readline-devel  libffi-devel

wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tar.xz

if [ $? -ne 0 ];then
   echo "网络故障"
   exit
fi

tar -xf Python-3.7.6.tar.xz
cd Python-3.7.6/
sed -ri 's/^#readline/readline/' Modules/Setup.dist
sed -ri 's/^#(SSL=)/\1/' Modules/Setup.dist
sed -ri 's/^#(_ssl)/\1/' Modules/Setup.dist
sed -ri 's/^#([\t]*-DUSE)/\1/' Modules/Setup.dist
sed -ri 's/^#([\t]*-L\$\(SSL\))/\1/' Modules/Setup.dist
./configure --enable-shared && make -j 2 && make install || echo "编译失败";exit
ldconfig