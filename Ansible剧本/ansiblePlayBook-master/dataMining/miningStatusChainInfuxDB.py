########## 用来分析链上的节点的算力占比，预期出块比例和实际出块比例，可以找到挖矿效率异常的节点
# 1.分析公网链上节点挖矿效率自动获取待分析的miner list：可以选择拿到该时间段有出块记录的miner list进行分析，或者获取power排名前30的miner list进行分析都可以
# 2.计算每个miner的全网算力比，预期出块比例，实际出块比例，有效转化率
# 3.找到有效转化效率偏高或者我们的节点偏低的节点，进行报警
########## Usage: minerIdList, 开始时间, 结束时间
import json
import os, sys
from datetime import datetime, timedelta
import time
import math
import parser
import requests
from influxdb import InfluxDBClient

def analyzeBlockRatio(minerIdList, startTime, endTime):
    # 获取该节点上链的block个数
    startTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
    endTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(endTime, "%Y-%m-%dT%H:%M:%S"))
    #如果日期是02格式,将前面的0去掉
    if(startTime_f.split(" ")[1].startswith('0')):
        startTime_f = startTime_f.replace("0", " ", 1)
        endTime_f = endTime_f.replace("0", " ", 1)
    chainListFileTmp = "chainList.txt_withTime"
    chainCmd = """ ~/bin/lotus chain list --count=2000 | awk -F'[()]' '{if($2>"%s" && $2<"%s")print $0}' > %s """ % (
        startTime_f, endTime_f, chainListFileTmp)
    os.popen(chainCmd)
    time.sleep(5)
    ###全网预期出块数
    struct_endTime, struct_startTime = time.mktime(time.strptime(endTime, "%Y-%m-%dT%H:%M:%S")), time.mktime(
        time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
    expectedBlockNum = (float(struct_endTime) - float(struct_startTime)) / blockTime
    ###实际出块数量
    totalBlockNum = os.popen("cat %s| wc -l" % chainListFileTmp).read().rstrip()

    ###全网总算力，大小为G
    # totalNetPower=3436351793922048/(1024*1024*1024) #G
    totalPowerCmd = "~/bin/lotus state power"
    totalNetPower = int(os.popen(totalPowerCmd).read().rstrip().split("(")[0]) / (1024 * 1024 * 1024)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "############################################################")
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "统计时间为 %s 至  %s , 期间全网预期出块个数 %s, 实际出块个数 %s" % (startTime, endTime, int(expectedBlockNum), totalBlockNum))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "############################################################")

    for minerId in minerIdList:
        # 保存三个信息,该miner的算力,预期出块率,实际出块率
        minerInfoDict = {}
        chainCidFile = "chainCid_" + minerId + ".txt"
        chainMinerCmd = """ grep %s %s> %s """ % (minerId, chainListFileTmp, chainCidFile)
        # print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"%s 节点出块中上链的信息保存为 %s"%(minerId,chainCidFile))
        os.popen(chainMinerCmd)
        # 分析出块比
        minerInfoDict["blockNum"] = os.popen("cat %s| wc -l" % chainCidFile).read().rstrip()
        nodePower = os.popen("~/bin/lotus state power %s" % minerId).read().rstrip()
        # print(minerId, nodePower)
        minerInfoDict["power"] = nodePower.split("(")[1].split(")")[0]
        # print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"#########  节点 %s 当前算力为： %s"%(minerId,minerInfoDict["power"]))
        power = nodePower.split("~= ")[-1].replace("%", "")
        minerInfoDict["powerRate"] = power
        expectRate = 1.0 - calZeroRate(float(power) / 100, totalNetPower)
        minerInfoDict["expectRate"] = format(expectRate * 100, '.2f')
        minerInfoDict["actualRate"] = format(float(minerInfoDict["blockNum"]) * 100 / float(expectedBlockNum), '.2f')
        if (int(minerInfoDict["blockNum"]) == 0):
            minerInfoDict["transRate"] = "0"
        else:
            minerInfoDict["transRate"] = format(
                float(minerInfoDict["actualRate"]) * 100 / float(minerInfoDict["expectRate"]), '.2f')
        sortPowerDict[minerId] = float(power)
        totalMinerDict[minerId] = minerInfoDict
        # print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"#########  节点 %s 当前算力为： %s"%(minerId,nodePower))
        # print ("                                       上链的block个数为: %s, 出块比例为: %s / %s = %s%%"%(nodeBlockNum,nodeBlockNum,totalBlockNum,nodeBlockRate))


def printAllMinerInfo(afterSort_list,totalMiner_dict):
    print("节点名称       power值      power占比      共出块个数      预期出块率      实际出块率    出块有效转化率")
    for i in afterSort_list:
        minerId = i[0]
        v = totalMiner_dict[minerId]
        print("%-10s   %10s   %10s%%  %10s     %10s%%      %10s%%     %10s%%" % (
            minerId, v["power"], v["powerRate"], v["blockNum"], v["expectRate"], v["actualRate"], v["transRate"]))


def calZeroRate(rate, totalPower):
    # totalPower=3*1024*1024 #G
    tmp = totalPower / sectorSize
    p = 5 * 25 / tmp
    num = math.ceil((tmp * rate) / 25.0)
    res = format((1 - p) ** num, '.4f')
    return float(res)


def calOneRate(rate, totalPower):
    tmp = totalPower / sectorSize
    p = 5 * 25 / tmp
    num = math.ceil((tmp * rate) / 25.0)
    res = (p ** 1) * ((1 - p) ** (num - 1)) * num
    return float(res)

def getMinerId(miner_num):
    import urllib.parse
    url_old = 'https://stats.testnet.filecoin.io/api/datasources/proxy/3/query?db=testnet&q=SELECT top("value", "miner", 30) as "power" FROM "chain.miner_power" WHERE time >= now() - 10m  &epoch=ms'
    url = url_old.replace("30", miner_num)
    minerID = []
    respons = requests.get(url)
    result = respons.text
    json_str = json.dumps(result)
    data = json.loads(json_str)
    x = json.loads(data)
    values = x['results'][0]['series'][0]['values']
    for miner in values:
        minerID.append(miner[2])
    return minerID

def getMinerIdFromDB(miner_num):
    selectMinerCmd = """SELECT top("value", "miner", 30) as "power" FROM "chain.miner_power" WHERE time >= now() - 40m"""
    selectMinerCmd = selectMinerCmd.replace("30", miner_num)
    result = client.query(selectMinerCmd)
    #print("=========")
    #for i in result.items():
    #    print(i[1]['time'])
    values = result.raw['series'][0]['values']
    minerID=[]
    for miner in values:
        minerID.append(miner[2])
    return minerID

def writeChainMiningStatusToInfluxDB(timestamp,miner_id,power_rate,expect_rate,actual_rate,trans_rate):
    json_body = [
        {
            "measurement": "data.ChainMiningStatus",
            "tags": {
                "minerId": miner_id
            },
            "time": timestamp,
            "fields": {
                "powerRate": power_rate,
                "expectRate": expect_rate,
                "actualRate": actual_rate,
                "transRate": trans_rate
            }
        }
    ]
    #print(json_body)
    return json_body

def writeToInfluxDB(afterSort_list,totalMiner_dict):
    # 时间为UTC时间,比北京时间提前了8个小时
    #timestamp = datetime.datetime.now()
    from datetime import datetime, timedelta
    now_time = datetime.now()
    utc_time = now_time - timedelta(hours=8)
    utc_time = utc_time.strftime("%Y-%m-%dT%H:%M:%SZ") 

    for i in afterSort_list:
        minerId = i[0]
        v = totalMiner_dict[minerId]
        jsonStr = writeChainMiningStatusToInfluxDB(utc_time, minerId, v["powerRate"], v["expectRate"], v["actualRate"], v["transRate"])
        client.write_points(jsonStr,time_precision='m') # 写入数据

if __name__ == '__main__':
    ##### Usage:  startTime和endTime是写清楚分析的时间段
    blockTime = 25  #s
    #sectorSize=float(32.0)  #G
    sectorSize=float(0.5)  #G
    #######################################
    import urllib.parse
    import argparse
    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--startTime', default="2020-03-19T19:00:00",type=str)
    parser.add_argument('--endTime', default="2020-03-19T20:00:00",type=str)
    parser.add_argument('--minerNum', default="5", type=str)
    args = parser.parse_args()
    startTime = args.startTime
    endTime = args.endTime
    minernum=args.minerNum
    ###获取一个小时前的时间
    startTime = (datetime.now() - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S")
    endTime = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    #######################################
    # 首先连接influxdb
    client = InfluxDBClient(host='192.168.100.6',port=8086,username='admin',password='admin',ssl=False,verify_ssl=False,database='lotus')

    ###从influxDB中获取miner list
    miner_list_tmp = getMinerIdFromDB(minernum)
    miner_list = list(set(miner_list_tmp))
    miner_list.sort(key=miner_list_tmp.index)
    #minerIdList = getMinerId(minernum)
    totalMinerDict = {}  # 全部的信息保存在这里
    sortPowerDict = {}  # 按照power倒序排列, minerId:powerRate
    ####分析指定时间段内minerIdList的挖矿比例
    ####保存三个信息,该miner的算力,预期出块率,实际出块率
    analyzeBlockRatio(miner_list, startTime, endTime)

    afterSortList = sorted(sortPowerDict.items(), key=lambda item: item[1], reverse=True)
    printAllMinerInfo(afterSortList,totalMinerDict)

    # 将信息写到influxDB
    writeToInfluxDB(afterSortList,totalMinerDict)