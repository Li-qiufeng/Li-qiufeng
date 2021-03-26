#!/bin/bash
cpu_load()
        {
        echo "CPU utilization and load"
        util=$(vmstat | awk '{if(NR==3)print 100-$15"%"}')
        user=$(vmstat | awk '{if(NR==3)print $13"%"}')
        sys=$(vmstat | awk '{if(NR==3)print $14"%"}')
        iowait=$(vmstat |awk '{if(NR==3)print $16"%"}')
        echo "Util: $util"
        echo "User use: $user"
        echo "System use: $sys"
        echo "I/O wait: $iowait"
        }
cpu_load
disk_load()
        {
        echo "Disk I/O and load"
        util=$(iostat -x -k |awk '/^[v|s]/{OFS=": ";print $1,$NF"%"}')
        fead=$(iostat -x -k |awk '/^[v|s]/{OFS=": ";print $1,$6"KB"}')
        write=$(iostat -x -k |awk '/^[v|s]/{OFS=": ";print $1,$7"KB"}')
        iowait=$(vmstat |awk '{if(NR==3)print $16"%"}')
        echo -e "Util: $util"
        echo -e "I/O Wait: $iowait"
        echo -e "Read/s: $read"
        echo -e "Write/s: $write"
        }
disk_load
mem_load()
	{       	
	echo "mem utilization and load"
	memtoal=$(free -m |awk '{if(NR==2)printf "%.1f",$2/1024}END{print "G"}')
        use=$(free -m |awk '{if(NR==2) printf "%.1f",$3/1024}END{print "G"}')
        free=$(free -m |awk '{if(NR==2) printf "%.1f",$4/1024}END{print "G"}')
        cache=$(free -m |awk '{if(NR==2) printf "%.1f",$6/1024}END{print "G"}')
        echo -e "Total: $memtoal"
        echo -e "Use: $use"
        echo -e "Free: $free"
        echo -e "Cache: $cache"
	}
mem_load > 1.txt
