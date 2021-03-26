##########################################################################
#Author:                    
#QQ:                         1********9
#Date:                       2020-03-16
#FileName:                   ssh-key.sh
#Description:                The test script
#Copyright (C):              2020 All rights reserved
##########################################################################
for node in $(cat ip.txt);do
  sshpass -p '1026' ssh-copy-id  ${node}  -o StrictHostKeyChecking=no -p 54077
	scp -P 54077 /etc/hosts ${node}:/etc/hosts
  if [ $? -eq 0 ];then
    echo "${node} 秘钥copy完成"
  else
    echo "${node} 秘钥copy失败"
  fi
done
