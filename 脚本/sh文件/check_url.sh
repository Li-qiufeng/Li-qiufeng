#!/bin/sh
. /etc/init.d/functions

URL=$*

usage() {
    # 提示脚本使用方法
    echo "USAGE: $0 url"
    exit 1
}



checkUrl(){
    wget -T 10 --spider -t 2 $1 > /dev/null 2>&1
    return $?
}


show_ret(){
    local retval=$1
    if [ ${retval} -eq 0 ];then
        action "You input $2 url is" /bin/true   
    else
        action "You input $2 url is" /bin/false
    fi
}

main(){
    if [ $# -ne 1 ];then
        usage
    fi
    checkUrl $1
    show_ret $? $1
}

main $URL
