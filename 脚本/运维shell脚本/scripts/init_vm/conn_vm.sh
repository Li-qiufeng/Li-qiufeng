#!/bin/env bash

for ip in $(cat $PWD/ip.txt)
do 
	ip[++i]=$ip
done
gnome-terminal --window -e "ssh ${ip[1]}" --tab -e "ssh ${ip[2]}" --tab -e "ssh ${ip[3]}" --tab -e "ssh ${ip[4]}" --tab -e "ssh ${ip[5]}"

