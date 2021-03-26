#!/usr/bin/env python3
# file name hello.py
def guess_number():
    print ("游戏开始")
    i = 0
    while i < 3:
        n = input("请输入一个数字: ")
        if n == 'q':
            break    
    
        if not (n and n.isdigit()):
            i = i + 1 

            if i == 3:
                inp = input("是否继续，继续请按y:")
                if inp == 'y':
                    i = 0
            continue
        n = int(n)
        
        if n == 18:
            print("猜对了")
            break
        elif  n > 18:
            print("大了")
            i = i + 1
        else:
            print("小了")
            i = i + 1
       
        if i == 3:
            inp = input("是否继续，继续请按y:")
            if inp == 'y':
                i = 0
    exit("退出程序...")
guess_number()
