#!/bin/env bash
while read line
do
	gnome-terminal --window --tab -x bash -c "ssh root@$line"
done < $PWD/tmp/ip.txt

