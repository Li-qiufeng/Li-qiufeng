for ip in 10.11.59.219
    do  
    scp /opt/erro.sh root@${ip}:/tmp/ &>/dev/null
    ssh root@${ip} "sh /tmp/erro.sh"  >>${HOME}/hostinfo.txt
done
