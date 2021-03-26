#!/usr/bin/bash
num=(1 2 3)
num2=(2 3 4)

array() {
	local factorial=1
	for i in $*
	do
		factorial=$[factorial * $i]
	done
	echo "$factorial"	
}

#array ${num[@]}
array ${num[*]} 	#数组所有元数值
array ${num2[*]} 	#数组所有元数值
