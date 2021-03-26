#!/bin/env bash
#v1.0
#物理备份
#1，tar备份数据
systemctl stop mysqld
mkdir /mysql_backup
tar -cJf /mysql_backup/`date +%F-%H`-mysql-all.tar.xz /var/lib/mysql
#2, tar还原数据
systemctl stop mysqld
rm -rf /var/lib/mysql/*
tar -xf /mysql_backup/xxxxxx.tar.xz -C /   #注意解压路径
systemctl start mysqld

#lvm快照备份数据
#1,数据迁移
# 准备lvm及文件系统
lvcreate -n mysql_lv -L 2G datavg  
mkfs.xfs /dev/datavg/mysql-lv

#迁移数据
systemctl stop mysqld
mount /dev/datavg/mysql_lv /mnt/                        #临时挂载点
cp -a /var/lib/mysql/* /mnt                             #将MySQL原数据镜像到临时挂载点

umount /mnt/
vim /etc/fstab                        			#加入fstab开机挂载
/dev/datavg/lv-mysql    /var/lib/mysql          xfs     defaults        0 0

mount -a
chown -R mysql.mysql /var/lib/mysql
systemctl start mysqld

echo "FLUSH TABLES WITH READ LOCK; SYSTEM lvcreate -L 500M -s -n lv-mysql-snap /dev/datavg/lv-mysql; " | mysql -p'(TianYunYang584131420)'
mysql -p'(TianYunYang584131420)'  -e 'show master status' > /backup/`date +%F`_position.txt

#从快照中备份
mount -o ro,nouuid /dev/datavg/lv-mysql-snap /mnt/           #xfs -o ro,nouuid xfs不支持uuid
cd /mnt/
tar -cf /backup/`date +%F`-mysql-all.tar ./*


#移除快照
cd; umount /mnt/
lvremove -f /dev/vg_tianyun/lv-mysql-snap 

back_dir=/backup/`date +%F`

[ -d $back_dir ] || mkdir -p $back_dir

echo "FLUSH TABLES WITH READ LOCK; SYSTEM lvcreate -L 500M -s -n lv-mysql-snap /dev/datavg/lv-mysql; \
UNLOCK TABLES;" | mysql -p'(TianYunYang584131420)'
mysql -p'(TianYunYang584131420)'  -e 'show master status' > /backup/`date +%F`_position.txt

mount -o ro,nouuid /dev/datavg/lv-mysql-snap /mnt/

rsync -a /mnt/ $back_dir

if [ $? -eq 0 ];then
         umount /mnt/
         lvremove -f /dev/datavg/lv-mysql-snap 
fi
