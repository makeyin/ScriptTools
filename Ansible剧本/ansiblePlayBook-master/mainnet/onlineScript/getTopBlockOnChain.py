import re
from datetime import datetime, timedelta
import os
from bs4 import BeautifulSoup
import requests
import argparse
def get_top_30miner():
        url = 'https://filfox.info/zh/ranks/power'
        headers = {
                'user-agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.15 Safari/537.36'}
        response = requests.get(url, headers=headers).content.decode('utf-8')
        html = BeautifulSoup(response, 'html.parser')
        text = str(html.body.text).replace(" ",",").split(",")
        list=[s for s in text if 'f0' in s]
        return list[0:31]

def getMinerInfo(fileName,startTime,endTime,minerid):
    try:
        with open("/home/devnet/bin/block.txt", 'w') as f1:
            f1.seek(0)
            f1.truncate()
            print("清空block.txt数据")
    except Exception :
        print("block.txt不存在，不用清空")
    for i in minerid:
         cmd_HandleIncoming = """grep  "\[HandleIncomingBlocks\]new block over pubsub" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}' |grep %s|awk '{print $10,$12}' |awk -F '"' '{print $2,$4}' >> ~/bin/block.txt """ % (fileName,startTime,endTime,i)
         os.popen(cmd_HandleIncoming).read().rstrip()
    cmd_get_chain="""~/bin/lotus chain list --count 3000 |awk -F "[" '{print $2}' |awk -F "]" '{print $1}' > ~/bin/chain_list.txt"""
    os.popen(cmd_get_chain).read().rstrip()
def diff_block():
    dict_log_miner={}
    dict_chain_block={}
    data = open("/home/devnet/bin/block.txt", 'r')
    for i in data:
        data1=i.replace(" ",",").replace("\n","").split(",")
        dict_log_miner[data1[0]]=data1[1]

    chain_data=open("/home/devnet/bin/chain_list.txt", 'r')
    for i in chain_data:
        chain_list=str(i).replace(" ","").replace("\n","").split(":")
        chain_list_data = " ".join(chain_list).replace(",", " ").replace(" ", ",").split(",")
        chain_data=chain_list_data[0:-1]
        for i in range(len(chain_data)):
            if i % 2 == 0:
                dict_chain_block[chain_data[i]] = chain_data[i + 1]

    for key in dict_log_miner.keys():
        NotOnChian=key in dict_chain_block.keys()
        if NotOnChian == False:
            print(key,dict_log_miner[key])

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--startTime', default="2020-06-08T17:00:00", type=str)
    parser.add_argument('--endTime', default="2020-06-08T17:20:00", type=str)
    parser.add_argument('--hour', default=0, type=int)
    parser.add_argument('--min', default=0, type=int)
    args = parser.parse_args()
    startTime = args.startTime
    endTime = args.endTime
    hour_interval = args.hour
    min_interval = args.min
    mlogFile_cmd = os.popen(
        "ls -altr ~/log | grep  lotus|tail -n 2 | awk '{print $9}'").read().rstrip()
    logFile_list = mlogFile_cmd.split("\n")
    merge_cmd = """cat ~/log/%s ~/log/%s > ~/log/lotus_merge_log""" % (logFile_list[0], logFile_list[1])
    logFile = "lotus_merge_log"
    os.popen(merge_cmd).read().rstrip()
    if (hour_interval != 0 or min_interval != 0):
        min_interval = min_interval
        startTime = (datetime.now() - timedelta(hours=hour_interval, minutes=min_interval)).strftime(
            "%Y-%m-%dT%H:%M:%S")
        endTime = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        startTime = startTime[:-2] + "00"
        endTime = endTime[:-2] + "00"
    First_thirty_miner=get_top_30miner()
    getMinerInfo(logFile, startTime, endTime,First_thirty_miner)
    diff_block()
