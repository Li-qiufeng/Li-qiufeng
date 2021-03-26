#!/bin/bash
factorial() {
factorial=1
#for((i=1;i<=$1;i++))
for i in `seq $1`
do
	#factorial=$[$factorial * $i]
	#let factorial=$factorial*$i
	let factorial*=$i
done
echo "$1 的阶cheng是: $factorial"
}

factorial $1
