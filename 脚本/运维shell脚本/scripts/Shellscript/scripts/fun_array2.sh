#!/usr/bin/bash
num=(1 2 3)

array() {
	local a=555
	local j
	local outarry=()
	for i
	do
		outarry[j++]=$[$i*5]
	done
	echo "${outarry[*]}"
}

#result=`array ${num[*]}; echo $a`
#echo ${result[*]}

array ${num[*]}
echo "a: $a"
#函数接收位置参数 $1 $2 $3 ... $n
#函数接收数组变量 $* 或 $@
#函数使用参数的个数 $#
#函数将接收到的所有参数赋值给数组 newarray=($*)
