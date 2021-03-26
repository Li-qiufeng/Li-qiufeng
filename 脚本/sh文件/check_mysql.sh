#!/bin/bash
read -p"SQLip:" HOSTNAME
PORT="3306"
USERNAME="root"
read -p "passwd:" PASSWORD
read -p "db_name:" DBNAME
TABLENAME="test_table_test"
#sql="/data/cqz/deploy/cqz/sql/init/0.0.2.35.init.sql"
sql="./zabbix.sql"
check_db_name_sql="SELECT count(SCHEMA_NAME) as SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DBNAME}'"
#create_db_sql="create database IF NOT EXISTS ${DBNAME}"
create_db_sql="CREATE DATABASE ${DBNAME} DEFAULT CHARACTER SET utf8;"
create_tables="source ${sql}"
MYSQL="mysql  -uroot  -h${HOSTNAME} -P${PORT} -p${PASSWORD} --default-character-set=utf8 -A -N"
ret_num=$(${MYSQL} -e "${check_db_name_sql}")

echo "------------------------------------------------------------------${ret_num}"
if [ "$ret_num" -eq 0 ];then
    echo "${DBNAME} 不存在"
    echo "正在创建数据库: ${DBNAME}"
    ${MYSQL} -e "${create_db_sql}"
    if [ $? -eq 0 ];then
        echo "数据库创建完成,准备导入数据"
        ${MYSQL}  $DBNAME < $sql
    fi
    # 查询导入到数据库中的表名称,并打印到终端
    ${MYSQL} -e "show tables from ${DBNAME}"
else
    echo "${DBNAME} 已存在"
fi
