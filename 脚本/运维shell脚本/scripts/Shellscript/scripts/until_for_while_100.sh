#!/usr/bin/bash
i=1
until [ $i -gt 100 ]
do
	let sum+=$i
	let i++
done
echo "sum: $sum"
