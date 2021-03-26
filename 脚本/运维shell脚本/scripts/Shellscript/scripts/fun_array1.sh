#!/usr/bin/bash
num=(1 2 3)
num2=(2 3 4)
array() {
	#echo "all parameters: $*"
	local newarray=($*)
	local i
	for((i=0;i<$#;i++))
	do
		newarry[$i]=$(( ${newarray[$i]} * 5 ))
	done
	echo "${newarry[*]}"
}

result=`array ${num[*]}`
echo ${result[*]}

result=`array ${num2[*]}`
echo ${result[*]}
