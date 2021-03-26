#!/bin/env bash
#v1.0
for ip in $(cat $PWD/tmp/ip.txt)
do
	{
	scp $PWD/init_mysql_yum.sh $ip:/tmp/
	}&
done

