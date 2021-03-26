题注：本套脚本为嘉为科技针对高济医疗现有linux运维环境定制脚本，具体实施调整应由高济医疗运维人员于企业内部实施，对外无效。

本套脚本共8个文件，分别对4个软件的单实例/集群场景，具体如下：
    1MySQL单实例：    Install_mysql5.7_single.sh
    2MySQL组复制：    Install_mysql5.7_mult.sh
    3Redis单实例：    Install_Redis_single.sh
    4Redis主从复制：  Install_Redis_repl.sh
    5Redis集群：      Install_Redis_cluster.sh
    6RocketMQ单实例： Install_RocketMQ_single.sh
    7RocketMQ集群：   Install_RocketMQ_cluster.sh
    8ES集群：         Install_ES_cluster.sh

说明：
1，本套脚本均采用无应答自动部署模式，并应具有可执行权限。
2，1、3、6单实例脚本无需修改内容，直接应用于单个目标系统即可；其余脚本为多台系统并行，并提前接收IP参数(RECEIVE.CLUSTER-IP---END.CLUSTER-IP)。
3，软件部署所需目录、压缩包、软件源等常用选项均定义于脚本起始变量，可于后期软件迭代手动更新，并注意调用关系。
4，脚本内-DISPLAY-及-fifo-项用于标记输出，请勿更改。
5，mysql脚本内有-PASSWORD-项，用于定于mysql管理员root密码。
6，脚本内部已对功能进行注解，部分说明如下：
  ScriptUsage：              用法           
  Check_User：               检查并创建用户
  Check_Group：              检查并创建组
  Check_Repo：               检查yum源有效
  Install_Basepackages：     安装基础依赖包
  Check_Dirs：               检查并创建目录
  InitDirs：                 初始化目录
  GetLanIp：                 获取本机IP
  Get_Package：              获取并解压软件包
  Set_Env：                  设置用户或系统环境变量
  Set_Cnf：                  设置配置文件
  Change_Jvm_Mem：           更改JVM虚拟机内存
  Start_XX：                 启动软件
  Check_Status：             检查状态
  TaskMain：                 主程序	
上述部分仅为常用函数，更多功能由脚本内细化函数决定，具体请参阅脚本本身。
	