#!/usr/bin/env python3
import subprocess 
cmd1 =" grep 'model name' /proc/cpuinfo | uniq "
a = subprocess.getoutput(cmd1).split(':')[1].strip() 

cmd2 = "grep 'physical id' /proc/cpuinfo | sort -u | wc -l"
b = subprocess.getoutput(cmd2)

cmd3 = "grep 'cpu cores' /proc/cpuinfo | uniq" 
c = subprocess.getoutput(cmd3).split(': ')[1] 

num = int(b)*int(c)
print("本服务器的 CPU 型号是:",a)
print("本服务器的 CPU 物理颗数是:",b)
print("本服务器每颗 CPU 的核心数是:",c)
print("本服务器 CPU 的总核心数是:",num)
