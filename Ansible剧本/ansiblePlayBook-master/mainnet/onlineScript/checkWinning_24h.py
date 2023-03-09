##### python3 checkWinning_mysql.py --hour=12
##### 安装依赖: pip3 install pymysql  -i https://pypi.tuna.tsinghua.edu.cn/simple/
#####
import os, sys
import json
import time
from datetime import datetime, timedelta
import numpy as np
import math


def to24TimeFormat(unixTime):
    time_local = time.localtime(int(unixTime))
    # 转换成新的时间格式(2016-05-05 20:28:54)
    dt = time.strftime("%Y-%m-%dT%H:%M:%S", time_local)
    return dt


def calZeroRate(rate, totalPower):
    # totalPower=3*1024*1024 #G
    tmp = totalPower / sectorSize
    p = 5 * 25 / tmp
    num = math.ceil((tmp * rate) / 25.0)
    res = format((1 - p) ** num, '.4f')
    return float(res)


def calExpectRate(rate):
    res = 0.0
    if (rate > 0.2):
        res = 1.0
    else:
        res = rate * 5.0
    return float(res)


def noSyncSelfBlock(fileName,startTime,endTime):
    time_list = []
    getSyncSubmitBlock = """grep  SyncSubmitBlock --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}' | awk '{print $10}' |awk -F '"' '{print $2}'""" % (fileName,startTime,endTime)
    SyncSubmitBlock_time = os.popen(getSyncSubmitBlock).read().rstrip()
    list_all_time = str(SyncSubmitBlock_time).split('\n')
    for time in list_all_time:
        if time[-2:] == "ms":
            getBlock_time = float(time[:-2]) / 1000
            if getBlock_time >= 6:
                time_list.append(getBlock_time)
        elif time[-2:] != "ms":
            getBlock_time = float(time[:-1])
            if getBlock_time >= 6:
                print(getBlock_time)
                time_list.append(getBlock_time)
    return len(time_list)

def getOnChainInfo(minerId, startTime, endTime):
    # 获取该节点上链的block个数
    startTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
    endTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(endTime, "%Y-%m-%dT%H:%M:%S"))
    # 如果日02格式,将前面的0去掉
    if (startTime_f.split(" ")[1].startswith('0')):
        startTime_f = startTime_f.replace("0", " ", 1)
    if (endTime_f.split(" ")[1].startswith('0')):
        endTime_f = endTime_f.replace("0", " ", 1)
    chainListFileTmp = "chainList.txt_withTime"
    chainCmd = """ ~/bin/lotus chain list --count=3000 | awk -F'[()]' '{if($2>"%s" && $2<"%s")print $0}' > %s """ % (
        startTime_f, endTime_f, chainListFileTmp)
    print("获取上链的block信息: ", chainCmd)
    os.popen(chainCmd)
    time.sleep(120)

    ###全网预期出块数
    struct_endTime, struct_startTime = time.mktime(time.strptime(endTime, "%Y-%m-%dT%H:%M:%S")), time.mktime(
        time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
    expectedNetBlockNum = (float(struct_endTime) - float(struct_startTime)) / block_time + 2
    ###实际出块数量
    totalBlockNum = os.popen("cat %s| wc -l" % chainListFileTmp).read().rstrip()

    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "############################################################")
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "统计时间 %s 至  %s , 期间全网预出个数 %s, 实际出块个数 %s" % (startTime, endTime, int(expectedNetBlockNum), totalBlockNum))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
          "############################################################")
    dbDataDict["loop_expect"] = expectedNetBlockNum
    dbDataDict["net_actual_block"] = totalBlockNum
    dbDataDict["empty_block_count"] = int(expectedNetBlockNum) - int(totalBlockNum)

    chainMinerCmd = """ grep %s %s> %s """ % (minerId, chainListFileTmp, onChainBlockFile)
    print("获取本节点最终上链的区块信息: ", chainMinerCmd)
    os.popen(chainMinerCmd)
    time.sleep(5)
    return expectedNetBlockNum


def getLogWithTime():
    # 按照需要的间段切割lotus日志
    # logFileWithinTimeCmd="""grep '^2020' --text %s| awk '{if($1 > "%s" && $1 < "%s"){print $0}}' > %s"""%(logFile,startTime,endTime,logFileWithTime)
    # os.popen(logFileWithinTimeCmd)
    # time.sleep(15)
    # 按���时间段切割lotus storage miner日志
    mlogFileWithinTimeCmd = """grep '^2021' --text ~/log/%s | egrep -a "mbi info timeout|mined block in the past|distribute win task|getBaseInfo finished took|IsComputeWin|mining delay|mined new block|mineOneSep|loop again|failed getting beacon entry|received wtask|attempting to mine a block" | awk '{if($1 > "%s" && $1 < "%s"){print $0}}' > %s""" % (
        mlogFile, startTime, endTime, mineLogFile)
    print("获取指定时间内的本地挖矿日志: ", mlogFileWithinTimeCmd)
    os.popen(mlogFileWithinTimeCmd)
    time.sleep(120)


def formatTimeInLog(old):
    # 单位转化为ms
    if ("ms" in old):
        new = float(old.split("ms")[0])
    elif ("m" in old and "ms" not in old):
        minutes = old.split("m")[0]
        seconds = old.split("m")[1].split("s")[0]
        new = float(minutes) * 60 * 1000 + float(seconds) * 1000
    elif ("µs" in old):
        new = float(old.split("µs")[0]) / 1000.0
    elif ("ns" in old):
        new = float(old.split("ns")[0]) / 1000000.0
    else:
        t = old.split("s")[0]
        new = (float(t) * 1000.0)
    return new


###{"cid": "bafy2bzaceccgzz7npjnr6uovliusao23wxguyojeomvnbinaeeukme6pidax2", "height": "215035", "totalTook": "27.515529086s",
### "mineOneSepTook": "23.25036ms", "disTook": "419.53528ms", "waitVaniTook": "7.000256777s", "computeSnarkProofsTook": "9.966813398s", "parents": ["f02775","f01231","f03249"]}

def calMineTimeCostNewLog(mineLogFile):
    cmd = """ egrep "mined new block" %s | awk -F'new block' '{print $2}' """ % (mineLogFile)
    # print(cmd)
    jsonStrList = os.popen(cmd).read().rstrip().split("\n")
    if (jsonStrList[0] == ""):
        return
    for j in jsonStrList:
        blockJson = json.loads(j.rstrip().lstrip())
        # print(blockJson)
        selfMinedBlockList.append(blockJson["cid"])
        Total_TimeList.append(formatTimeInLog(blockJson["totalTook"]))
        mineOneSep_TimeList.append(formatTimeInLog(blockJson["mineOneSepTook"]))
        disTook_TimeList.append(formatTimeInLog(blockJson["disTook"]))
        waitVani_TimeList.append(formatTimeInLog(blockJson["waitVaniTook"]))
        computeSnarkProofs_TimeList.append(formatTimeInLog(blockJson["computeSnarkProofsTook"]))


# mineOneSep      {"totalTook": "23.04688ms", "mbiTook": "13.74733ms", "ticketTook": "3.36083ms", "isWinTook": "1.67258ms", "randTook": "4.43µs",
# "sindexTook": "328.74µs", "assembleTook": "3.03571ms"}
def calMineoneSepTimeCost(mineLogFile):
    cmd = """ egrep "mineOneSep" %s | grep ticketTook |  awk -F'mineOneSep' '{print $2}' """ % (mineLogFile)
    print(cmd)
    jsonStrList = os.popen(cmd).read().rstrip().split("\n")
    if (jsonStrList[0] == ""):
        return
    for j in jsonStrList:
        if (j == ""):
            continue
        blockJson = json.loads(j.rstrip().lstrip())
        mineOneSepTotal_TimeList.append(formatTimeInLog(blockJson["totalTook"]))
        mbiTook_TimeList.append(formatTimeInLog(blockJson["mbiTook"]))
        # beaconTook_TimeList.append(formatTimeInLog(blockJson["beaconTook"]))
        ticketTook_TimeList.append(formatTimeInLog(blockJson["ticketTook"]))
        isWinTook_TimeList.append(formatTimeInLog(blockJson["isWinTook"]))
        randTook_TimeList.append(formatTimeInLog(blockJson["randTook"]))
        sindexTook_TimeList.append(formatTimeInLog(blockJson["sindexTook"]))
        assembleTook_TimeList.append(formatTimeInLog(blockJson["assembleTook"]))
        # disTook_TimeList.append(formatTimeInLog(blockJson["disTook"]))


def printNumpyRes(alist, name):
    avg = format(np.average(alist), '.2f')
    std = format(np.std(alist), '.2f')
    minV = format(np.min(alist), '.2f')
    maxV = format(np.max(alist), '.2f')
    v10 = format(np.percentile(alist, 10), '.2f')
    v50 = format(np.percentile(alist, 50), '.2f')
    v60 = format(np.percentile(alist, 60), '.2f')
    v70 = format(np.percentile(alist, 70), '.2f')
    v80 = format(np.percentile(alist, 80), '.2f')
    v90 = format(np.percentile(alist, 90), '.2f')
    v95 = format(np.percentile(alist, 95), '.2f')
    v97 = format(np.percentile(alist, 97), '.2f')
    v98 = format(np.percentile(alist, 98), '.2f')
    v99 = format(np.percentile(alist, 99), '.2f')
    # print ("phase          avg         std         min         10%分位         50%���         90%分位         95%分位         97%分位         98%分位         99%分位         max")
    # print(name,avg,std,minV,v10,v50,v90,maxV)
    print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s   %10s   %10s  %10s  %10s  %10s  %10s  %10s  %10s" % (
        name, avg, std, minV, v10, v50, v60, v70, v80, v90, v95, v97, v98, v99, maxV))


def saveWinningDataToDB(data_dict):
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    tableName = "tr_winning_data"
    # print (conn)
    print(data_dict)

    # print (type(conn))
    # conn.select_db('tr_burn_money')
    cur = conn.cursor()  # 获取游标

    # 另一种插入数据的方式，通过字符串传入值
    sql = "insert into tr_winning_data values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    cur.execute(sql, (
        data_dict["date_run_time"],
        data_dict["start_time"],
        data_dict["end_time"],
        data_dict["customer_name"],
        data_dict["miner_id"],
        data_dict["loop_expect"],
        data_dict["net_actual_block"],
        data_dict["empty_block_count"],
        data_dict["loop_actual"],
        data_dict["fail_beacon_count"],
        data_dict["winning_count"],
        data_dict["not_winning_count"],
        data_dict["mbi_timeout"],
        data_dict["poster_ret_count"],
        data_dict["send_poster_fail"],
        data_dict["poster_not_return"],
        data_dict["mined_new_count"],
        data_dict["mined_past_block"],
        data_dict["sync_submit_overtime"],
        data_dict["onchain_count"],
        data_dict["not_onchain_count"],
        data_dict["less_base_count"],
        data_dict["expect_mining_rate"],
        data_dict["actual_mining_rate"],
        data_dict["lucky_rate"],
        data_dict["lucky_rate_filfox"],
        data_dict["duplicate_base"]

    ))

    conn.commit()
    cur.close()
    conn.close()


def analyzeSelfMinedBlock():
    # 获取上链的block cid集合
    selfOnChainBlockStr = os.popen("cat %s" % onChainBlockFile).read().rstrip()
    selfOnChainBlockNum = os.popen("cat %s | wc -l" % onChainBlockFile).read().rstrip()

    # 打印本节点挖到了但是没有上链的block cid
    # selfMinedBlockList = os.popen("cat %s| awk '{print $NF}'"%selfCreatedBlockFile).read().rstrip().split("\n")
    selfMinedNum = len(selfMinedBlockList)
    lostBlockList = []
    for blockCid in selfMinedBlockList:
        if (blockCid not in selfOnChainBlockStr):
            lostBlockList.append(blockCid)
            # print(blockCid)

    loopCount = os.popen("grep 'loop again' %s | wc -l" % mineLogFile).read().rstrip()
    print("************************loopCount",loopCount)
    getBeaconFailCount = os.popen(
        "grep 'failed getting beacon entry' %s | grep 310853 | wc -l" % mineLogFile).read().rstrip()
    winnerTrueCount = os.popen(
        """ grep IsComputeWin %s | awk -F'Count":' '{print $NF}' | awk -F'}' '{print $1}' | grep -v 0 | wc -l """ % mineLogFile).read().rstrip()
    print("-------winnerTrueCount",winnerTrueCount,mineLogFile)
    winnerFalseCount = os.popen(
        """ grep IsComputeWin %s | awk -F'Count":' '{print $NF}' | awk -F'}' '{print $1}' | grep 0 | wc -l """ % mineLogFile).read().rstrip()
    receiveSlaveSuccessCount = os.popen(""" grep "received wtask intime" %s | wc -l """ % mineLogFile).read().rstrip()
    mbiTimeoutCount = os.popen(""" grep "mbi info timeout" %s | wc -l """ % mineLogFile).read().rstrip()
    sendToPosterFailedCount = os.popen(
        """ grep "received wtask timeout" %s | grep "sents: 0"| wc -l """ % mineLogFile).read().rstrip()
    receiveSlaveFailedCount = os.popen(
        """ grep "received wtask timeout" %s | grep "received: 0"| grep "sents: 1" | wc -l """ % mineLogFile).read().rstrip()
    miningDelayCount = os.popen(""" grep "mined block in the past" %s | wc -l """ % mineLogFile).read().rstrip()
    minedBlockCount = os.popen(""" grep "mined new block" %s |wc -l """ % mineLogFile).read().rstrip()
    print("该时间段理论的挖矿轮数: ", int(expectedNetBlockNum))
    print("  本节点触发挖矿的次数: ", loopCount, "        未拿到beacon的次数: ", getBeaconFailCount)
    print("    master刮中奖的次数: ", winnerTrueCount, "        未刮中奖的次数: ", winnerFalseCount, "       mbi超时: ",
          mbiTimeoutCount)
    print("   收到poster返回的次数: ", receiveSlaveSuccessCount, "     发送给poster失败: ", sendToPosterFailedCount,
          "     未收到poster返回: ", receiveSlaveFailedCount)
    print("          挖到矿的次数: ", minedBlockCount)
    print("            上链的个数: ", selfOnChainBlockNum, "     挖到past时间区块: ", miningDelayCount)

    # print("====超时被截断的日志")
    # miningDelayLogs=os.popen(""" grep "mining delay" %s"""%mineLogFile).read().rstrip()
    # print(miningDelayLogs)

    ###计算期望的出块率
    # 全网总算，大小为G
    totalPowerCmd = "~/bin/lotus state power"
    totalNetPower = int(os.popen(totalPowerCmd).read().rstrip().split("(")[0]) / (1024 * 1024 * 1024)
    nodePower = os.popen("~/bin/lotus state power %s" % selfMinerId).read().rstrip()
    power = nodePower.split("~= ")[-1].replace("%", "")
    # expectRate = 1.0 - calZeroRate(float(power)/100,totalNetPower)
    expectRate = calExpectRate(float(power) / 100)
    expectRate = round(expectRate * 100, 2)
    actualSelfRate = round(float(selfMinedNum) * 100 / float(expectedNetBlockNum),2)
    actualOnlineRate = round(float(selfOnChainBlockNum) * 100 / float(expectedNetBlockNum),2)
    Lucky_value = float(actualSelfRate) / float(expectRate)
    dbDataDict["mined_past_block"] = miningDelayCount
    dbDataDict["loop_actual"] = loopCount
    dbDataDict["fail_beacon_count"] = getBeaconFailCount
    dbDataDict["winning_count"] = winnerTrueCount
    dbDataDict["not_winning_count"] = winnerFalseCount
    dbDataDict["mbi_timeout"] = mbiTimeoutCount
    dbDataDict["poster_ret_count"] = receiveSlaveSuccessCount
    dbDataDict["send_poster_fail"] = sendToPosterFailedCount
    dbDataDict["poster_not_return"] = receiveSlaveFailedCount
    dbDataDict["mined_new_count"] = minedBlockCount
    dbDataDict["onchain_count"] = selfOnChainBlockNum

    # print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"节点 %s 此间本地总共挖到的block个数为 %s"%(selfMinerId,selfMinedNum))
    print(
        "------------------------------------------------------------------------------------------------------------------------")
    print("%-10s %10s %10s %10s %10s %10s %10s" % ("预期出块率", "本地挖到数量", "本地出块率", "上链数量", "上链出块率", "未上链数量", "未上链率"))
    if (selfMinedNum != 0):
        lostRate = format(len(lostBlockList) * 100 / selfMinedNum, '.2f')
    else:
        lostRate = 0.0
    print("%6s%%     %12s    %14s%%    %12s     %12s%%     %12s    %12s%%" % (
        expectRate, selfMinedNum, actualSelfRate, selfOnChainBlockNum, actualOnlineRate, len(lostBlockList), lostRate))
    print(
        "------------------------------------------------------------------------------------------------------------------------")
    dbDataDict["not_onchain_count"] = len(lostBlockList)
    dbDataDict["expect_m_rate"] = expectRate
    dbDataDict["expect_mining_rate"] = '%s%%'% round(expectRate,2)

    dbDataDict["actual_m_rate"]=format(float(selfOnChainBlockNum)*100/float(expectedNetBlockNum), '.2f')
    print(type(dbDataDict["actual_m_rate"]))

    lucky_rate=format(
        float(dbDataDict["actual_m_rate"]) * 100 / float(dbDataDict["expect_m_rate"]), '.2f')

    dbDataDict["lucky_rate"] = '%s%%' % lucky_rate

    dbDataDict["less_base_count"] = 0
    actual_mining_rate= format(float(selfOnChainBlockNum) * 100 / float(expectedNetBlockNum), '.2f')

    dbDataDict["actual_mining_rate"] = '%s%%' % round(float(actual_mining_rate),2)


    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "未上链的block cid分别为：")
    if (lostBlockList == []):
        print("无")
    else:
        # print(lostBlockList)
        print("%-30s                                 %10s    %10s     %10s" % (
            "block_cid", "height", "createdtime_fromLog", "block_timestamp"))
        for cid in lostBlockList:
            height = os.popen(
                "~/bin/lotus chain getblock %s| grep Height | awk '{print $NF}'| awk -F',' '{print $1}'" % cid).read().rstrip()
            if (height == ""):
                print(cid, "  该block本地查询不到")
                continue
            timeU = os.popen(
                "~/bin/lotus chain getblock %s| grep Timestamp | awk '{print $NF}'| awk -F',' '{print $1}'" % cid).read().rstrip()
            parentsList = os.popen(
                """ ~/bin/lotus chain getblock %s | jq '.Parents[]|."/"' """ % cid).read().rstrip().replace('"',
                                                                                                            '').split(
                "\n")
            heightP = int(height) - 1
            chainParentList = os.popen(""" ~/bin/lotus chain list --height=%s --count=1 """ % heightP).read().rstrip()
            if (timeU == ''):
                timeU = -1
            else:
                timeU = to24TimeFormat(timeU)
            timeLog = os.popen("grep %s %s|awk '{print $1}'" % (cid, mineLogFile)).read().rstrip()
            if (chainParentList.count(": f0") - len(parentsList) > 0):
                dbDataDict["less_base_count"] = dbDataDict["less_base_count"] + 1

            print("%-30s %10s   %20s    %20s" % (cid, height, timeLog.split(".")[0], timeU))
            print("failed block's parent: ", parentsList)
            print("on chain block's parent: ", chainParentList)
            print("")


def delete_files(logfilename, mlogfilename):
    for root, dirs, filesin in os.walk(path):
        for filename in filesin:
            if filename == logfilename or filename == mlogfilename:
                os.remove(os.path.join(filename))
                print("Delete file:", (filename))


def get_Lucky(minet_id):
    from bs4 import BeautifulSoup
    import requests
    url = 'https://filfox.info/zh/address/%s' % minet_id
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.15 Safari/537.36'}
    response = requests.get(url, headers=headers).content.decode('utf-8')
    html = BeautifulSoup(response, 'html.parser')
    text = html.body.div.text
    text_list = str(text).split(":")
    result_Lucky = text_list[20].split(" ")
    return result_Lucky[1]


if __name__ == '__main__':
    ##### Usage:  startTime和endTime是写清楚分析的时间段
    logFile = os.popen("ls -altr ~/log | grep  lotus | grep -v _withTime |tail -n 1 | awk '{print $9}'").read().rstrip()
    # mlogFile = "storage-miner.05181838.out"
    mlogFile_cmd = os.popen(
        "ls -altr ~/log | grep  lotus-winning | grep -v _withTime |tail -n 2 | awk '{print $9}'").read().rstrip()
    logFile_list = mlogFile_cmd.split("\n")
    merge_cmd = """cat ~/log/%s ~/log/%s > ~/log/winning_merge_log""" % (logFile_list[0], logFile_list[1])
    mlogFile = "winning_merge_log"
    os.popen(merge_cmd).read().rstrip()

    block_time = 30  # s
    sectorSize = float(32.0)  # G
    dbDataDict = {}
    #######################################


    dbDataDict["date_run_time"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    import argparse

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
    if (hour_interval != 0 or min_interval != 0):
        ###采用相对时间，获取hour_interval和min_interval 前的时间
        min_interval = min_interval
        startTime = (datetime.now() - timedelta(hours=hour_interval, minutes=min_interval)).strftime(
            "%Y-%m-%dT%H:%M:%S")
        endTime = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        startTime = startTime[:-2] + "00"
        endTime = endTime[:-2] + "00"
        # print(startTime[:-2])
    SyncSubmitBlockNum=noSyncSelfBlock(logFile,startTime,endTime)
    dbDataDict["sync_submit_overtime"] = SyncSubmitBlockNum
    DictMinerName = {"f01475": "1475",
                     "f014386": "1475",
                     "f020618": "1475",
                     "f020452": "1475",
                     "f021461": "1475",
                     "f021547": "1475",
                     "f045756": "1475",
                     "f061051": "矿无界",
                     "f065881": "熵",
                     "f079815": "火星云矿",
                     "f086240": "Karl",
                     "f087256": "蝶恋科技",
                     "f089551": "奶牛",
                     "f096172": "北京三人组",
                     "f0103665": "欧巴-思密达",
                     "f030408": "三号矿场",
                     "f022804": "星际公链",
                     "f029665": "阳区块链",
                     "f021961": "熊猫",
                     "f023882": "矿无界",
                     "f01314":"基金",
                      "f0110996":"蝶链(new)",
                     "f0111007": "股东福利",
                     "f023499": "赛道"}

    dbDataDict["start_time"] = startTime
    dbDataDict["end_time"] = endTime

    ###求出本节点的miner id
    exportCmd = """export  FULLNODE_API_INFO=`grep "FullNodeToken" .lotuswinning/config.toml | grep -v "^#" | awk -F'=' '{print $NF}'` """
    get_attempting_block="""grep  "attempting to mine a block"  --text ~/log/winning_merge_log  | awk '{if($1 > "%s" && $1 < "%s"){print $0}}'| awk '{print $1,$5,$6,$7,$8,$9,$11}' | awk -F'"' '{print $2}' | uniq -c | awk '{if($1==2) print $0}' | wc -l"""%(startTime, endTime)
    attempting_block_num= os.popen(get_attempting_block).read().rstrip()
    selfMinerId = os.popen("~/bin/lotus-winning info | grep 'Miner:' | awk '{print $NF}'").read().rstrip()
    Lucky_Filfox = get_Lucky(selfMinerId)
    dbDataDict["duplicate_base"] = attempting_block_num
    dbDataDict["miner_id"] = selfMinerId
    minerName = DictMinerName[selfMinerId]
    dbDataDict["customer_name"] = minerName
    dbDataDict["lucky_rate_filfox"] = Lucky_Filfox
    # print(selfMinerId)
    if (selfMinerId == ""):
        print("请先执行export FULLNODE_API_INFO=XXXXX")
        exit(0)

    ###按照需求分离和切割日志
    # logFileWithTime=logFile + "_withTime"
    mlogFileWithTime = mlogFile + "_withTime"
    mineLogFile = "mineLog_" + selfMinerId + ".txt"
    # selfCreatedBlockFile="selfCreatedCid_"+selfMinerId +".txt"
    getLogWithTime()

    ###  统计mineoneSep时间分布
    ### {"totalTook": "289.042248ms", "mbiTook": "267.650854ms", "beaconTook": "1.509µs",
    # "ticketTook": "8.394182ms", "isWinTook": "6.776472ms", "randTook": "472.48µs", "sindexTook": "753.416µs", "assembleTook": "3.67696ms", "disTook": "34.357µs"}
    mineOneSepTotal_TimeList = []
    mbiTook_TimeList = []
    beaconTook_TimeList = []
    ticketTook_TimeList = []
    isWinTook_TimeList = []
    randTook_TimeList = []
    sindexTook_TimeList = []
    assembleTook_TimeList = []

    calMineoneSepTimeCost(mineLogFile)
    if (mineOneSepTotal_TimeList == []):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "挖矿相关的日志为空,请检查日志")
        # sys.exit(1)average
    else:
        print(
            "-------------------------------------------------------- 统计 mineoneSep 时间分布 (ms) ------------------------------------------------------------------")
        print("%-16s   %10s   %10s   %10s   %10s   %10s  %10s  %10s  %10s  %10s  %10s   %10s   %10s  %10s  %10s" % (
            "[module]", "[avg]", "[std]", "[min]", "[10th]", "[50th]", "[60th]", "[70th]", "[80th]", "[90th]", "[95th]",
            "[97th]", "[98th]", "[99th]", "[max]"))
        printNumpyRes(mbiTook_TimeList, "mbiTook")
        # printNumpyRes(beaconTook_TimeList,"beaconTook")
        printNumpyRes(ticketTook_TimeList, "ticketTook")
        printNumpyRes(isWinTook_TimeList, "isWinTook")
        printNumpyRes(randTook_TimeList, "randTook")
        printNumpyRes(sindexTook_TimeList, "sindexTook")
        printNumpyRes(assembleTook_TimeList, "assembleTook")
        # printNumpyRes(disTook_TimeList,"disTook")
        printNumpyRes(mineOneSepTotal_TimeList, "mineOneSepTotal")
        print(
            "--------------------------------------------------------------------------------------------------------------------------------------------------------")
        print("\n")

    ###  统计挖矿的时间分布
    selfMinedBlockList = []
    mineOneSep_TimeList = []
    disTook_TimeList = []
    waitVani_TimeList = []
    computeSnarkProofs_TimeList = []
    Total_TimeList = []
    calMineTimeCostNewLog(mineLogFile)
    if (selfMinedBlockList == []):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "该时段内没有挖到矿!!!")
    else:
        print(
            "--------------------------------------------------------- 统计 new block 时间分布 (ms) ------------------------------------------------------------------")
        print("%-16s   %10s   %10s   %10s   %10s   %10s   %10s   %10s   %10s  %10s  %10s   %10s   %10s  %10s  %10s" % (
            "[module]", "[avg]", "[std]", "[min]", "[10th]", "[50th]", "[60th]", "[70th]", "[80th]", "[90th]", "[95th]",
            "[97th]", "[98th]", "[99th]", "[max]"))
        printNumpyRes(mineOneSep_TimeList, "mineOneSeperate")
        printNumpyRes(waitVani_TimeList, "waitVani")
        printNumpyRes(disTook_TimeList, "disTook")
        printNumpyRes(computeSnarkProofs_TimeList, "computeSnarkProofs")
        printNumpyRes(Total_TimeList, "total")
        print(
            "--------------------------------------------------------------------------------------------------------------------------------------------------------")
        print("\n")

    ###获取指定时间段内的链上的区块信息
    onChainBlockFile = "onChainCid_" + selfMinerId + ".txt"
    expectedNetBlockNum = getOnChainInfo(selfMinerId, startTime, endTime)
    # path="/home/devnet/log"

    ###分析节点本地的挖到的block信息
    analyzeSelfMinedBlock()
    # delete_files(logFileWithTime,mlogFileWithTime)
    # saveWinningDataToDB(dbDataDict)