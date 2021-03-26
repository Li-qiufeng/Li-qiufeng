#!/bin/bash

readme="
  使用方法：\n
     支持监控号查询和流水号查询\n
     支持的日期格式为 20180116 或 201801*\n
     示例1： 7101537580  20180116\n
     示例2： 29997000125268541 2018011*\n
"
echo -e ${readme}

while :
do
    # -a 变量名    接收到的数据定义为一个数组
    # -r 变量名    每次都先清除 变量的值
    read -r -a input_info -p  "请输入[q 退出]>: " 
    
    choice=${input_info[@]}
    case   ${choice} in
    q | quit )
        exit 
        ;;
    # 不是 q 就进一步判断输入的参数是否符合要求
    *)
        # 获取到输入的参数个数
        num=${#input_info[@]}

        case ${num} in
        2)
            # 查询的项目
            item=${input_info[0]}

            # 数据
            inp_date=${input_info[1]}

            # 时间格式 2020-03-17
            s_date="${inp_date:0:4}-${inp_date:4:2}-${inp_date:6:2}" 

            # [ ${#item} -eq 10 -o ${#item} -eq 17 ] 
            # 等同于
            # [ ${#item} -eq 10 ] || [ ${#item} -eq 17 ]

            if [ ${#item} -eq 10 -o ${#item} -eq 17 ]
            then
                clear
                echo 
                echo 
                grep ${item} /weblogic/logs/nohup.${s_date}.log | awk -F'报文内容:' '{print $2}' > str_content.json
                test $? -eq 0 && /usr/bin/env python  /home/view/bin/QuerySystem/bin/querystart.py
                echo
                echo
            else
                clear
                echo
                echo -e ${readme}
                echo 
                echo "监控号是 10 位， 流水号是 17 位"
                echo
            fi
        ;;
        *)
            clear
            echo
            echo -e ${readme}
            echo
            echo "需要两个参数，参数之间用空格隔开"
            echo
        ;;
        esac
    ;;
    esac 
done

#grep 7101537580 /weblogic/logs/nohup.2018-01-16.log | awk -F'报文内容:' '{print $2}' > /home/view/bin/QuerySystem/conf/str_content.json

#/usr/bin/env python  /home/view/bin/QuerySystem/bin/querystart.py
