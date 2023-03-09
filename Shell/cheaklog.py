#!/usr/bin/python
# encoding=utf-8
# Filename: monitorLog.py
import os
import signal
import subprocess
import time
import smtplib
from email.mime.text import MIMEText
from email.header import Header
import requests
import json
import threading
 
serverName="prod:window"
 
#日志文件路径地址
logFiles =[
"/home/devnet/peerid.log"
];
 
#机器人回调地址 , 钉钉群里添加一个机器人就可以了
webhook = 'https://oapi.dingtalk.com/robot/send?access_token=1a711e904fffae6d3249b7970d98b147cbeac26ad44174a6c71eb2dbcb22a4e9'
 
#日志缓存数据
logs = []
 
#记录日志行数，从匹配行开始记录，到达数量就用推给钉钉机器人
rows = 1
 
# 是否开始记录日志标记位
recordFlags = []
 
# 检测的关键字数组，大小写敏感
keywords = []
keywords.append("machine")
 
#消息内容,url地址
def dingtalk(msg,webhook):
    headers = {'Content-Type': 'application/json; charset=utf-8'}
    data = {'msgtype': 'text', 'text': {'content': msg}, 'at': {'atMobiles': [], 'isAtAll': False}}
    post_data = json.dumps(data)
    response = requests.post(webhook, headers=headers, data=post_data)
    return response.text
 
 
 
# 检查行
def checkLine(line, index):
    curLog = logs[index]
    if recordFlags[index]==1:
        curLog.append(line)
        if len(curLog)>rows:
            content = "\n".join('%s' %id for id in curLog)
            print(content)
            dingtalk(content,webhook)
            recordFlags[index] = 0
            logs[index]=[]
    else:
        for keyword in keywords:
            if keyword in line:
                recordFlags[index] = 1
                curLog.append(serverName)
                curLog.append(logFiles[index])
                curLog.append(line)
                break
 
#日志文件一般是按天产生，则通过在程序中判断文件的产生日期与当前时间，更换监控的日志文件
#程序只是简单的示例一下，监控test1.log 10秒，转向监控test2.log
def monitorLog(logFile, index):
    #print('监控的日志文件 是%s' % logFile)
    popen = subprocess.Popen('tail -f ' + logFile, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    pid = popen.pid
    print('Popen.pid:' + str(pid))
    while True:
        line = popen.stdout.readline().strip()
        # 判断内容是否为空
        if line:
            #print line
            checkLine(str(line), index)
 
if __name__ == '__main__':
    for index, logFile in enumerate(logFiles):
        logs.append([])
        recordFlags.append(0)
        tt = threading.Thread(target=monitorLog,args=(logFile,index))
        tt.start()
        print ("monitor:"+str(logFile))