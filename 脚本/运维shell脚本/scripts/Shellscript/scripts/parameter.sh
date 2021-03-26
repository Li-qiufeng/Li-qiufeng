#!/usr/bin/bash
if [ $# -ne 3 ];then
	echo "usage: `basename $0` par1 par2 par3"
	exit
fi

fun3() {
	echo "$(($1 * $2 * $3))"
}

result=`fun3 $1 $2 $3`
echo "result is: $result"
