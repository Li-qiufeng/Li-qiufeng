#！/usr/bin/env python3
import subprocess
ipa = 'ip a'
ip1 = subprocess.getoutput(ipa).split('\n')
for line in ip1: 
    if 'inet' in line and '127.0.0.1' not in line and 'inet6' not in line: 
        li = []
        li.append('ip地址：')
        li.append(line.split()[1])
        li.append('网卡名称：') 
        li.append(line.split()[-1]) 
        print(li)  
