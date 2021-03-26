#!/usr/bin/bash
while [ $# -ne 0 ]
do
	useradd $1
	echo "$1 is created"
	shift 1
done
