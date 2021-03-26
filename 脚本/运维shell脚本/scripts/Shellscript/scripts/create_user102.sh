#!/usr/bin/bash
#v1.0 by tianyun
if [ $# -eq 0 ];then
	echo "usage: `basename $0` file"
	exit 1
fi

if [ ! -f $1 ];then
	echo "error file"
	exit 2
fi

#希望for处理文件按回车分隔，而不是空格或tab空格
#重新定义分隔符
#IFS内部字段分隔符
#IFS=$'\n'
IFS='
'
for line in `cat $1`
do
	echo "1111111111111111111111111111111111"
	#if [ ${#line} -eq 0 ];then
	#	echo "Nothing to do"
	#	continue
	#fi
	user=`echo "$line" |awk '{print $1}'`
	pass=`echo "$line" |awk '{print $2}'`
	id $user &>/dev/null
	if [ $? -eq 0 ];then
		echo "user $user already exists"
	else
		useradd $user
		echo "$pass" |passwd --stdin $user &>/dev/null
		if [ $? -eq 0 ];then
			echo "$user is created."
		fi
	fi
done
