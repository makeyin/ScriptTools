import json
import os, sys
import datetime, time
import numpy as np
import requests


def filterLogTime(start_time, end_time, file_name):
    cmd = """ grep -E "new block over pubsub" --text %s|awk '{if($1>"%s" && $1<"%s")print $1 $10 $12}' > %s""" % (
        logFile, start_time, end_time, file_name)
    os.popen(cmd)
    time.sleep(5)


def getMinerInfo(miner_id_list, r_file_name, w_file_name):
    id_list_str = "|".join(miner_id_list)
    cmd = """grep -E "%s" %s > %s """ % (id_list_str, r_file_name, w_file_name)
    print("view_cmd", cmd)
    os.popen(cmd)
    time.sleep(5)

def printNumpyRes(alist, name):
    avg = format(np.average(alist), '.2f')
    std = format(np.std(alist), '.2f')
    minV = format(np.min(alist), '.2f')
    maxV = format(np.max(alist), '.2f')
    v10 = format(np.percentile(alist, 10), '.2f')
    v50 = format(np.percentile(alist, 50), '.2f')
    v90 = format(np.percentile(alist, 90), '.2f')
    print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s" % (name, avg, std, minV, v10, v50, v90, maxV))

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
            time_atimeArray = datetime.datetime.strptime(time2[0], "%Y-%m-%dT%H:%M:%S")
            chain_block_int = int(time.mktime(time_atimeArray.timetuple()))
            chain_block_final = str(chain_block_int) + time2[1]
            time_stamp_diff = miner_info["timestamp"]
            init_block_stamp = datetime.datetime.strptime(time_stamp_diff, "%Y-%m-%dT%H:%M:%S")
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


# def extractMineridTimeDiff(file_name):
#     from pprint import pprint
#     with open(file_name, 'r') as f:
#         text = f.readline()
#         print(text)
#     dict_before = text.split(";")
#     ex_dict = {}
#     for x in dict_before:
#         split_list = x.split(",")
#         if len(split_list) == 2:
#             if split_list[0] not in ex_dict.keys():
#                 ex_dict[split_list[0]] = []
#                 ex_dict[split_list[0]].append(split_list[1])
#             else:
#                 ex_dict[split_list[0]].append(split_list[1])
#     for key, value in ex_dict.items():
#         name = key
#         float_list = []
#         for i in value:
#             float_list.append(float(i))
#         printNumpyRes(float_list, name)
#

# def backHostTime():
#     local_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
#     index_value = int(local_time[11:13])
#     back_time = str(index_value - 2).zfill(2)
#     local_time_str = str(index_value)
#     get_time = local_time.replace(local_time_str, back_time, ).replace(local_time[10], "T")
#     print("将查询%s之后的blcok_time_diff" % (get_time))
#     return get_time


def minerId(miner_num):
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


def delete_files(file_name):
    for root, dirs, filesin in os.walk(path):
        for filename in filesin:
            if filename == file_name:
                os.remove(os.path.join(filename))
                print("delete", (filename))


if __name__ == '__main__':
    import argparse

    path = "/home/devnet/log"
    logFile = os.popen("ls -l /home/devnet/log | grep  lotus | grep -v _withTime |tail -n 1 | awk '{print $9}'").read().rstrip()

    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--start_time', default="2020-03-06T19:00:00", type=str)
    parser.add_argument('--end_time', default="2020-03-06T20:00:00", type=str)
    parser.add_argument('--miner_num', default="5")
    args = parser.parse_args()
    miner_num = args.miner_num
    start_time = args.start_time
    end_time = args.end_time

    first_file_name = "incision_log_file.txt"  # 第一步从时间切出log存放文件
    second_file_name = "incision_minerid.txt"
    filterLogTime(start_time, end_time, first_file_name)
    miner_list = minerId(miner_num)
    getMinerInfo(miner_list, first_file_name, second_file_name)
    print_dict = {}
    getBlockMinerInfo(second_file_name)

    print(
        "---------------------------------------------------------------------------------------------------------------")
    print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s" % (
        "[minerID]", "[avg]", "[std]", "[min]", "[10th]", "[50th]", "[90th]", "[max]"))
    for i in print_dict.keys():
        printNumpyRes(print_dict[i], i.replace('"', ''))

    delete_files(first_file_name)
