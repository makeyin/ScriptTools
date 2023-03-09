##### 用来统计两条日志的时间差
##### Usage： 修改logpFile参数即可，输出的时间是unix时间戳，ms单位
##### 安装numpy：用root运行 pip3 install numpy  -i https://pypi.tuna.tsinghua.edu.cn/simple/
import os,sys
import datetime,time
import numpy as np
import math

def printNumpyRes(alist,name):
  ###
  avg = format(np.average(alist),'.2f')
  std = format(np.std(alist),'.2f')
  minV = format(np.min(alist),'.2f')
  maxV = format(np.max(alist),'.2f')
  v10 = format(np.percentile(alist,10),'.2f')
  v50 = format(np.percentile(alist,50),'.2f')
  v90 = format(np.percentile(alist,90),'.2f')
  print("---------------------------------------------------------------------------------------------------------------")
  print ("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s"%("[module]","[avg]","[std]","[min]","[10th]","[50th]","[90th]","[max]"))
  #print ("phase          avg         std         min         10%分位         50%分         90%分位         max")
  #print(name,avg,std,minV,v10,v50,v90,maxV)
  print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s"%(name,avg,std,minV,v10,v50,v90,maxV))

logpFile="poster.02252032.out"
tmpFile="candidateTime.txt"
cmd=""" grep -E "slave start tranfer winner res to master|poster start handle winner tasks requset" %s""" %(logpFile)
#cmd=""" grep -E "slave start tranfer winner res to master|poster start handle winner tasks requset" %s > %s""" %(logpFile,tmpFile)
#cmd=""" grep "new block over pubsub" ~/log/%s | grep -v 18067 | grep -v 16971 | tail -n 100 |awk -F'"' '{print $4}'|uniq """ %(logFile)
run = os.popen(cmd)
logList = run.read().rstrip().split("\n")

logLen = len(logList)

timeDeltaList=[]

for i in range(0,int(12)):
#for i in range(0,int(logLen/2)):
  start = logList[2*i]
  end = logList[2*i+1]
  if("start handle winner tasks" in start and "start tranfer winner res" in end):
    sTList = start.split("+")[0].split(".")
    #print("sTList ",sTList)
    t1=sTList[0]
    t2_ms = sTList[1]
    t3 = datetime.datetime.strptime(t1,"%Y-%m-%dT%H:%M:%S")
    num_time = int(time.mktime(t3.timetuple()))
    start_time_unix = str(num_time) + t2_ms

    eTList = end.split("+")[0].split(".")
    t1=eTList[0]
    t2_ms = eTList[1]
    t3 = datetime.datetime.strptime(t1,"%Y-%m-%dT%H:%M:%S")
    num_time = int(time.mktime(t3.timetuple()))
    end_time_unix = str(num_time) + t2_ms
    #print(start_time_unix,end_time_unix)
    timeDeltaList.append(int(end_time_unix) - int(start_time_unix))

printNumpyRes(timeDeltaList,"slave_candidate")