
# 声明关联数组
declare -A arr2

# 定义数据
arr=(a b c d e f g h i j k l m n o p)
arr2=([a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [h]=7)


# 获取到当前虚拟机所有的磁盘名称
disks=$(virsh domblklist ${vm_name} |grep 'vd' | cut -d ' ' -f 1)

# 获取到最后一个磁盘名称
last_disk_num=$(echo $disks|awk -F 'vd' '{print $NF}')

# 找到下一个磁盘名称的最后那个字母在数据 arr 中的索引号, 比如 6
index=$(echo ${arr2[$last_disk_num]})

# 通过索引号找到下一个磁盘名称的最后那个字母，比如 f
next_word=$(echo ${arr[$index]})

# 拼接出需要添加的磁盘名称
disk_name=vd${next_word}

