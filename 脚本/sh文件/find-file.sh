# 设置Chmap日志内容汇总的日志名                                                                                                                                       

check_chmap_file=check_chmap_file_log 

get_chmap_file_name() {                                                                                                                                                 
    # 用于获取到 /app/log/ 和 /backup/log/ 下面的所有 Chmap_File_Recv.debuge 日志
                                                                                                                                                                   
    bak_log_f_name=$(ls /backup/log/Chmap_File_Recv.debug*  2> /dev/null)                                                                                             
                                                                                                                                                                      
    app_log_f_name=$(ls /app/log/Chmap_File_Recv.debug*  2> /dev/null)                                                                                                
                                                                                                                                                                      
    file_name_list="${bak_log_f_name} ${app_log_f_name}"                                                                                                              
                                                                                                                                                                      
    if [ -z "$file_name_list" ]                                                                                                                                       
    then                                                                                                                                                              
        echo "文件名没有获取到"                                                                                                                                       
    else                                                                                                                                                              

        >  ${check_chmap_file}                                                                                                                                             

        for file in ${file_name_list}                                                                                                                                 
        do                                                                                                                                                            
            cat ${file} >> ${check_chmap_file}                                                                                                                                 
        done                                                                                                                                                          
   fi                                                                                                                                                                 
}                                                                                                                                                                     

jzsq_function (){    
    #处理集中授权文件日志情况                                                                                                                                                      
    get_chmap_file_name

    echo                         接收集中授权文件处理检查�                                                                                                       
    echo ---------------------------------华丽的分割线----------------------------------                                                                          
    echo                                                                                                                                                          
    awk '/99700290000_SMCTL_AHR_INST_0000_'${date}'_I_0001_0001.xml/ {print $0}'  ${check_chmap_file} | awk  -F '[| ]+' '/ap_File_Recv.pc/ {print $1"\t"$2"\t" $13"\t"$15}'
    awk '/99700290000_AMCTL_AHR_MODE_0000_'${date}'_I_0001_0001.xml/ {print $0}'  ${check_chmap_file} | awk  -F '[| ]+' '/ap_File_Recv.pc/ {print $1"\t"$2"\t" $13"\t"$15}'
    echo                                                                                                                                                          
    echo ---------------------------------华丽的分割线----------------------------------                                                                          
}                                                                                                                                                                     
                                                                                                                               
#处理电子印章文件日志情况                                                                                                                                             

dzyz_function (){        
  
        get_chmap_file_name
                                                                                                                                                   
        echo                 "接收并处理电子印章文件的结果如下："                                                                                                     
        echo --------------------------------------------------------------------------------                                                                         
        echo                                                                                                                                                          
        echo ${date_1}
        echo ${check_chmap_file}
        awk '/99701150000_EJYQL_0000_'${date_1}'_I_0001_0001.xml/ {print $0}' ${check_chmap_file} |awk '/ap_File_Recv.pc/ {print $9"\t"$11}'
        awk '/99701150000_EJGQL_0000_'${date_1}'_I_0001_0002.xml/ {print $0}' ${check_chmap_file} |awk '/ap_File_Recv.pc/ {print $9"\t"$11}'
        echo                                                                                                                                                          
        echo ---------------------------------华丽的分割线----------------------------------                                                                          
}                                                                                                                                                                     

# 发往逻辑系统的文件情况检查                                                                                                                                          
                                                                                                                                                                      
send_ljxt_file (){                                                                                                                                                    
        tail -5  /app/log/LgCnCheck_Main.debug || tail -5 /backup/log/LgCnCheck_Main.debug                                                                            
}                                                                                                                                                                     

#接收并处理现金凭证文件的日志情况                                                                                                                                     

till_function_1 (){
   
       # get_chmap_file_name
                                                                                                                                               
       echo "函数内值班日期：${date}"                                                                                                                                 
       echo "函数内日切日期：${date_1}"                                                                                                                               

        grep -e  "99700090000_CERT_REGLT_APPR_CHK_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_CERT_GRANT_CANCEL_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_NET_CSH_SEND_CRTFILE_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_CSH_REGLT_APPR_CHK_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_CSH_NETBK_PAYCANCEL_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_APPR_CANCEL_0000_${date}_I_0001_0001.xml"\
             -e  "99700090000_CERT_NETHANDIN_CHK_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_PRE_MET_0000_${date}_A_0001_0001.xml" \
             -e  "99700090000_OVER_RECEIVE_CRTFILE_0000_${date}_I_0001_0001.xml"\
             -e  "99700090000_LACK_GIVE_CRTFILE_0000_${date}_I_0001_0001.xml"    \
             -e  "99700090000_CERT_GRANT_CRTFILE_0000_${date}_I_0001_0001.xml"    \
             -e  "99700090000_CSH_REV_NET_PAY_CHK_0000_${date}_I_0001_0001.xml"   \
             -e  "99700090000_NET_VOU_APPLY_CRTFILE_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_AUTOBANKPERLMT_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_NODEREC_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_CERTINFO_0000_${date}_I_0001_0001.xml"  \
             -e  "99700090000_NODEPERLMT_0000_${date}_I_0001_0001.xml"  \
             -e  "99700090000_HIERARCHICAL_AUTH_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_ATMPERLMT_0000_${date}_I_0001_0001.xml"  \
             -e  "99700090000_TRANSREL_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_TLRPERLMT_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_CERTLMT_0000_${date}_I_0001_0001.xml" \
             -e  "99700090000_NET_CSH_APPLY_CRTFILE_0000_${date}_I_0001_0001.xml"  \
             /app/log/Chmap_File_Recv.debug*
        echo ---------------------------------华丽的分割线----------------------------------

        echo "在00:40之后才处理的文件的结果:"
        grep -e "99700090000_NET_DRAW_CASH_0000_${date}_I_0001_0001.xml" \
             -e "99700090000_BANK_HANDIN_MOD_0000_${date}_I_0001_0001.xml" \
             -e "99700090000_BANK_REC_CRTFILE_0000_${date}_I_0001_0001.xml" \
             -e "99700090000_BANK_HANDIN_CRTFILE_0000_${date}_I_0001_0001.xml" \
             -e "99700090000_NET_STORE_CASH_0000_${date}_I_0001_0001.xml" \
              /app/log/Chmap_File_Recv.debug*
        echo ---------------------------------华丽的分割线----------------------------------
}


till_function_2 (){

        reslut=`till_function_1`

        echo "$reslut" |grep -v 'UnpackMsg' |awk '/Mon/ {printf "\n %-64s %-s \n",$9,$11}'|cat -b
}

#机构柜员文件处理结的日志情况

jggy_function (){

        get_chmap_file_name

        echo "                 【机构柜员】文件处理结果存储过程                             " 
        echo ---------------------------------华丽的分割线---------------------------------- 
        echo
        echo "【机构】文件消息通知接收情况:"                                                                                                                          
        awk  -F '[\]\[/]' '/获取文件名\[99700050000/ {print $1,$11 }'   ${check_chmap_file}                                                                                   
        echo                                                                                                                                                          
        echo "从 FTP 服务器获取文件情况V"                                                                                                                             
        awk -F '[\]\[| ]' '/FileName\[99700050000/  && $11 ~ /eftp_/ {print $1,$2,$12,$13,$14,$16}'   ${check_chmap_file}                                                     
        echo                                                                                                                                                          
        echo "【机构】文件处理存储过程"                                                                                                                               
        awk  '/pro_newdeptpub/ ' ${check_chmap_file}                                                                                                                          
        echo                                                                                                                                                          
        echo ---------------------------------华丽的分割线----------------------------------                                                                          
        echo                                                                                                                                                          
        echo "【柜员】文件消息通知接收情况:"                                                                                                                          
        awk -F'[|\[]' '/获取文件名\[99700060000/ {print $1,$2,$8}' ${check_chmap_file}                                                                                         
        echo                                                                                                                                                          
        echo "从 FTP 服务器获取文件情况"                                                                                                                              
        awk -F '[\]\[| ]' '/FileName\[99700060000/  && $11 ~ /eftp_/ {print $1,$2,$12,$13,$14,$16}'  ${check_chmap_file}                                                      
        echo                                                                                                                                                          
        echo "【柜员】文件处理存储过程"                                                                                                                               
        grep  PRO_OPERINFOSYN_NEW      ${check_chmap_file}                                                                                                                    
        echo                                                                                                                                                          
        echo ---------------------------------华丽的分割线----------------------------------                                                                          
}                                                                                                                                                                     

#**************************************发送文件*******************************************#                                                                           


reslut_a="99700040000_CERT_USE_0000_${date}_I_0001_0001.xml
99700040000_PAY_OUT_TO_LESS_IN_0000_${date}_A_0001_0006.xml
99700040000_NET_MORE_OUT_0000_${date}_A_0001_0006.xml
99700040000_NET_MORE_DEAL_0000_${date}_A_0001_0006.xml
99700040000_NET_LESS_IN_0000_${date}_A_0001_0006.xml
99700040000_NET_LESS_DEAL_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_STOP_CRT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_LOST_FIND_CRT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_LOST_CRT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_ALLOT_OUT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_ALLOT_IN_0000_${date}_A_0001_0006.xml
99700040000_IN_COME_TO_MORE_OUT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_WST_CRT_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_SND_CRT_0000_${date}_A_0001_0006.xml
99700040000_CASH_ALLOT_TLR_ALLOT_0000_${date}_A_0001_0006.xml
99700040000_BROKEN_CHG_0000_${date}_A_0001_0006.xml
99700040000_CASH_CORR_REG_SND_0000_${date}_A_0001_0006.xml
99700040000_BOX_DRAW_MNG_0000_${date}_A_0001_0006.xml
99700040000_CERT_ALLOT_TLR_REG_0000_${date}_A_0001_0006.xml
99700040000_NET_GRP_CASH_SND_0000_${date}_A_0001_0006.xml
99700040000_NET_EXC_CASH_SND_0000_${date}_A_0001_0006.xml
99700040000_NET_CASH_SND_CRT_0000_${date}_A_0001_0006.xml
99700040000_CASH_SND_REG_SND_0000_${date}_A_0001_0006.xml
99700040000_NET_GRP_CASH_RCV_0000_${date}_A_0001_0006.xml
99700040000_NET_CASH_RCV_CRT_0000_${date}_A_0001_0006.xml
99700040000_CASH_RCV_REG_SND_0000_${date}_A_0001_0006.xml
99700040000_CASH_ALLOT_TLR_SND_0000_${date}_A_0001_0006.xml
99700040000_BOX_BAL_0000_${date}_A_0001_0006.xml
99700040000_BOX_CRT_0000_${date}_A_0001_0006.xml
99700040000_CASH_ALLOT_TLR_APP_0000_${date}_A_0001_0006.xml
99700040000_CHECK_ATM_TOT_REG_0000_${date}_A_0001_0006.xml
99700040000_NETAUTO_ALLOT_0000_${date}_A_0001_0006.xml
99700040000_CHECK_ATM_DTL_REG_0000_${date}_A_0001_0006.xml
99700040000_NET_CERT_RCV_CRT_0000_${date}_A_0001_0006.xml
99700040000_CERT_PARAM_DTL_0000_${date}_A_0001_0006.xml
99700040000_NET_CASH_ALLOT_OUT_0000_${date}_A_0001_0006.xml
99700040000_NET_CASH_ALLOT_IN_0000_${date}_A_0001_0006.xml
99700040000_ATM_CASH_SND_0000_${date}_A_0001_0006.xml
99700040000_ATM_CASH_ADD_0000_${date}_A_0001_0006.xml
99700040000_CHECK_CASH_REG_0000_${date}_A_0001_0006.xml
99700040000_CHECK_TOT_REG_0000_${date}_A_0001_0006.xml
99700040000_CHECK_CERT_REG_0000_${date}_A_0001_0006.xml
99700040000_CASH_REG_SEND_0000_${date}_A_0001_0006.xml
99700040000_INT_CHECK_0000_${date}_I_0001_0001.xml
99700040000_BOX_CERT_NUM_0000_${date}_A_0001_0006.xml"


reslut_b="99700040000_INST_RECPAY_NEW_0000_${date}_A_0001_0006.xml
99700040000_PBX_CLEAR_ONDATE_0000_${date}_A_0001_0006.xml
99700040000_ATM_CERT_ALLOT_IN_0000_${date}_A_0001_0006.xml
99700040000_ATM_CERT_WASTE_CANCEL_0000_${date}_A_0001_0006.xml
99700040000_ATM_CERT_SND_CRT_CANCEL_0000_${date}_A_0001_0006.xml
99700040000_ATM_CERT_LOST_CANCEL_0000_${date}_A_0001_0006.xml
99700040000_ATM_CERT_ALLOT_OUT_0000_${date}_A_0001_0006.xml
99700040000_PBX_CLEAR_CANCLE_ONDATE_0000_${date}_A_0001_0006.xml
99700040000_BOX_DRAW_REG_0000_${date}_A_0001_0006.xml
99700040000_CERT_SEQ_DAY_0000_${date}_A_0001_0006.xml
99700040000_LC_CERT_USE_REG_0000_${date}_A_0001_0006.xml
99700040000_NET_FORMAL_CHECK_TOT_0000_${date}_A_0001_0006.xml
99700040000_NET_FORMAL_CHECK_DET_0000_${date}_A_0001_0006.xml"

snd_xjpz2 (){
        n=0
        echo "正常的话，下面应该是00:00前【8】个,00:30前应该总共【13】个"
        for i in $reslut_b
        do
        n=$(($n+1))
        grep $i /app/log/SndCheckXml* | awk '/Mon Msg/ {printf "%-3s%-65s %-40s \n", '"$n"',$5,$6}'
        done

        n=0
        echo "正常的话，下面应该是00:00前【41】总共应该是【45】个"
        for i in $
        do
        n=$(($n+1))
        grep $i /app/log/SndCheckXml* | awk '/Mon Msg/,NF > 3 {print  $10,$11,$12}' | awk -F '文件通知消息' '{printf "%-3s%-68s %82s \n",'"$n"',$1,$2}'
        #grep $i /app/log/SndCheckXml* | awk '/Mon Msg/,NF > 3 {print  $10,$11,$12}' #| awk -F '文件通知消息' '{print $0}'
        done
}

sndhj1 (){
        grep -e  99700040000_APPLY_GOLD_0000_${date}_A_0001_0006.xml \
         -e 99700040000_ALLOT_OUT_IN_0000_${date}_A_0001_0006.xml  \
         -e 99700040000_CHECK_BUYBACK_0000_${date}_A_0001_0006.xml \
         -e 99700040000_ORDER_AGENCY_0000_${date}_A_0001_0006.xml \
         -e 99700040000_WASTE_LOST_0000_${date}_A_0001_0006.xml \
         -e 99700040000_WASTE_QUALITY_LOST_0000_${date}_A_0001_0006.xml \
        /app/log/SndCheckXml*
}


snd_hj2 (){

        reslut3=$(sndhj1)

        echo "$reslut3" |awk '/Mon/ {printf "\n %-60s %s\n",$10,$12}'|cat -b

}

ch_ser_num (){
        ssh 21.0.8.11 "diff ${date}check_server_all.txt ${date_1}check_server_all.txt"
        if [ $? == 0 ];then
        echo
        echo
        echo
        echo
        echo
        echo
        echo "****************************************"
        echo "*                                      *"
        echo "*         [ 服务数和昨天一样 ]         *"
        echo "*                                      *"
        echo "****************************************"
        else
        echo "**********************************************************"
        echo "*                                                        *"
        echo "*         [ 服务数和昨天不一样，请确认是否正常 ]         *"
        echo "*                                                        *"
        echo "**********************************************************"
        fi
}
ch_his_dayend (){
        # 检查日终日志
        echo
        echo
        echo
        echo
        echo
        echo
        echo "*******************************************************************"
        echo
        echo "        请登录 21.0.132.82"
        echo "        执行 su - dbimport"
        echo "        Qdglpt.vsp1"
        echo "        44"
        echo "        awk '/操作/ {print \$3,\"=\",\$8}' DBTOOLS_DayEnd_{A,B}.${date_1}* |awk -F '[-=]' '{printf \"%-3s%-33s%-25s%8s %s \\n\", NR,\$1,\$2,\$3,\$6}'"
        echo
        echo "*******************************************************************"
}

ch_big_db_f (){
        # 检查给会计稽核的文件
        echo "****************************************"
        echo
        echo "        请登录 21.0.132.84:view"
        echo
        echo "        tail /home/view/big/log/SndFileToBigData_YICHANG.debug"
        echo
        echo "****************************************"
}

# 检查现金凭证流水融合文件

ch_lsrh_file (){
        tail /app/log/SndFile2ZJQS_CHK_DIFF.debug
}



ch_lsds (){
    tail /app/log/MvDataToH.debug
    done_time=$(ls -l /app/log/MvDataToH.debug |awk '{print $8}')
    echo "完成时间: ${done_time}"
}

#13  检查现金凭证的 YKBF 文件

ch_to_xjpz_ykbf_file(){
        file_name=SndCheckXml_PBX_YKBF.debug
        log_path=/app/log
        back_log_path=/backup/log
        if [ -f $log_path/$file_name ]
        then
            grep SndCheckXml $log_path/$file_name
        else
            grep SndCheckXml  $back_log_path/$file_name
        fi
}


# 检查给现金凭证系统的收支表

ch_xjpz_szb(){

    file_name=SndCheckXml_PBX_FORM.debug
    file_dir=/app/log
    file_back_dir=/backup/log
    if [ -f ${file_dir}/${file_name} ]
    then
        grep PBX_FORM ${file_dir}/${file_name}
    else
        grep PBX_FORM ${file_back_dir}/${file_name}
    fi
}
