import json
import os, sys
import time
from datetime import datetime, timedelta
import numpy as np
import requests
from influxdb import InfluxDBClient

def filterLogTime(start_time, end_time, log_file, file_name):
    cmd = """grep -E "new block over pubsub" %s |awk '{if($1>"%s" && $1<"%s")print $1 $10 $12}' > %s""" % (
        log_file, start_time, end_time, file_name)
    print(cmd)
    os.popen(cmd)
    time.sleep(5)

def getMinerInfo(miner_id_list, r_file_name, w_file_name):
    id_list_str = "|".join(miner_id_list)
    cmd = """grep -E "%s" %s > %s """ % (id_list_str, r_file_name, w_file_name)
    print("view_cmd", cmd)
    os.popen(cmd)
    time.sleep(5)

def printNumpyRes(alist, name):
    n_dict = {}
    n_dict["avg"] = format(np.average(alist), '.2f')
    n_dict["std"] = format(np.std(alist), '.2f')
    n_dict["minV"] = format(np.min(alist), '.2f')
    n_dict["maxV"] = format(np.max(alist), '.2f')
    n_dict["v10"] = format(np.percentile(alist, 10), '.2f')
    n_dict["v50"] = format(np.percentile(alist, 50), '.2f')
    n_dict["v90"] = format(np.percentile(alist, 90), '.2f')
    print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s" % (name, n_dict["avg"], n_dict["std"], n_dict["minV"], n_dict["v10"], n_dict["v50"], n_dict["v90"], n_dict["maxV"]))
    numpy_dict[name]=n_dict

def getBlockMinerInfo(file_name):
    miner_info = {}
    with open(file_name, "r") as file:
        for line in file.readlines():
            miner_id = line.split(',')[1]
            block_time = line.split('+')[0]
            block_cid = line.split('"')[1]
            miner_info["minerid"] = miner_id
            miner_info["blockid"] = block_cid
            miner_info["blocktime"] = block_time
            cid = miner_info["blockid"]

            time_stamp = """~/bin/lotus chain  getblock "%s" | grep Time | awk  '{print $2 }' | head -c -2 """ % (cid)
            try:
                get_time = os.popen(time_stamp).read()
                judge = str.isdigit(get_time)
            except Exception as e:
                print(e)
            if judge == False:
                break
            get_time_int = int(get_time)
            timeArray = time.localtime(get_time_int)
            otherStyleTime = time.strftime("%Y-%m-%dT%H:%M:%S", timeArray)
            miner_info["timestamp"] = otherStyleTime
            block_time_diff = miner_info["blocktime"]
            time2 = block_time_diff.split(".")
            time_atimeArray = datetime.strptime(time2[0], "%Y-%m-%dT%H:%M:%S")
            chain_block_int = int(time.mktime(time_atimeArray.timetuple()))
            chain_block_final = str(chain_block_int) + time2[1]
            time_stamp_diff = miner_info["timestamp"]
            init_block_stamp = datetime.strptime(time_stamp_diff, "%Y-%m-%dT%H:%M:%S")
            block_time_int = int(time.mktime(init_block_stamp.timetuple()))
            block_time_final = str(block_time_int) + "000"
            diff_num = int(chain_block_final) - int(block_time_final)
            miner_info["block_diff_num"] = diff_num
            # print(miner_info)
            if (miner_id in print_dict.keys()):
                print_dict[miner_id].append(diff_num)
            else:
                print_dict[miner_id] = []
                print_dict[miner_id].append(diff_num)

def getMinerIdFromDB(miner_num):
    selectMinerCmd = """SELECT top("value", "miner", 30) as "power" FROM "chain.miner_power" WHERE time >= now() - 60m"""
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

def writeBlockTimeDiffToInfluxDB(timestamp,miner_id,avg,std,percent_10,percent_50,percent_90):
    json_body = [
        {
            "measurement": "data.BlockTimeDiff",
            "tags": {
                "minerId": miner_id
            },
            "time": timestamp,
            "fields": {
                "avg": avg,
                "std": std,
                "percent_10": percent_10,
                "percent_50": percent_50,
                "percent_90": percent_90
            }
        }
    ]
    #print(json_body)
    return json_body

def writeToInfluxDB(print_dict):
    # 时间为UTC时间,比北京时间提前了8个小时
    #timestamp = datetime.datetime.now()
    from datetime import datetime, timedelta
    now_time = datetime.now()
    utc_time = now_time - timedelta(hours=8)
    utc_time = utc_time.strftime("%Y-%m-%dT%H:%M:%SZ")

    for i in numpy_dict.keys():
        minerId = i
        v = numpy_dict[i]
        jsonStr = writeBlockTimeDiffToInfluxDB(utc_time, minerId, v["avg"], v["std"], v["v10"], v["v50"], v["v90"])
        client.write_points(jsonStr,time_precision='m') # 写入数据

def delete_files(file_name):
    for root, dirs, filesin in os.walk(path):
        for filename in filesin:
            if filename == file_name:
                os.remove(os.path.join(filename))
                print("delete", (filename))

def getStartEndTime(delta_hour):
    local_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
    index_value = int(local_time[11:13])
    back_time = str(index_value - 2).zfill(2)
    local_time_str = str(index_value)
    get_time = local_time.replace(local_time_str, back_time, ).replace(local_time[10], "T")
    print("将查询%s之后的blcok_time_diff" % (get_time))
    return get_time

if __name__ == '__main__':
    import argparse
    path = "/root/log"
    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--start_time', default="2020-03-20T12:00:00", type=str)
    parser.add_argument('--end_time', default="2020-03-20T14:00:00", type=str)
    parser.add_argument('--miner_num', default="5")
    args = parser.parse_args()
    miner_num = args.miner_num
    start_time = args.start_time
    end_time = args.end_time
    first_file_name = path + "/blocktime_log.txt"  # 第一步从时间切出log存放文件
    second_file_name = path + "/blocktime_minerid.txt"
    logFile = os.popen("cd /root/log; ls -al | grep  lotus | grep -v _withTime |tail -n 1 | awk '{print $9}'").read().rstrip()
    print("logFile: ",logFile)

    ###获取一个小时前的时间
    start_time = (datetime.now() - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S")
    end_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    ###获取一个小时前的lotus日志
    filterLogTime(start_time, end_time, path+"/"+logFile,first_file_name)
    #######################################
    # 首先连接influxdb
    client = InfluxDBClient(host='192.168.100.6',port=8086,username='admin',password='admin',ssl=False,verify_ssl=False,database='lotus')

    ###从influxDB中获取miner list
    miner_list_tmp = getMinerIdFromDB(miner_num)
    miner_list = list(set(miner_list_tmp))
    miner_list.sort(key=miner_list_tmp.index)
    ###分析指定时间段内minerIdList的挖矿比例
    getMinerInfo(miner_list, first_file_name, second_file_name)
    print_dict = {}
    numpy_dict = {}
    getBlockMinerInfo(second_file_name)

    print(
        "------------------------------------------------本节点接收miner的block的时间差(ms)---------------------------------------------------------------")
    print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s" % (
        "[minerID]", "[avg]", "[std]", "[min]", "[10th]", "[50th]", "[90th]", "[max]"))
    for i in print_dict.keys():
        printNumpyRes(print_dict[i], i.replace('"', ''))

    # 将信息写到influxDB
    writeToInfluxDB(numpy_dict)
    delete_files(first_file_name)