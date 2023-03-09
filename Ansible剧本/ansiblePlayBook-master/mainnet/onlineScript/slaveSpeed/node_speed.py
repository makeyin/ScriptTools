import requests
from retrying import retry
import json
import os
import time
from datetime import datetime, timedelta
import pymysql

def print_red(*s, end='\n'):
    for item in s:
        print('\033[31m {} \033[0m'.format(item), end='')
    print(end=end)

def print_green(*s, end='\n'):
    for item in s:
        print('\033[32m {} \033[0m'.format(item), end='')
    print(end=end)

def print_yellow(*s, end='\n'):
    for item in s:
        print('\033[33m {} \033[0m'.format(item), end='')
    print(end=end)

def print_blue(*s, end='\n'):
    for item in s:
        print('\033[34m {} \033[0m'.format(item), end='')
    print(end=end)

def print_date(*s, end='\n'):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), end=' ')
    for item in s:
        print(item, end='')
    print(end=end)

def get_slave_speed():
    list_cmd=[]
    cmd_minerID="""cat slave_info.txt|awk '{print $2}' | sort | uniq"""
    miner_all=os.popen(cmd_minerID).read().rstrip()
    tmp_list =miner_all.split("\n")
    # 去掉list中可能存在的非矿工号码的字符
    miner_list =  [d for d in tmp_list if d.startswith("f0")]
    sizeDict = {}
    sizeDict = get_miner_sector_size(miner_list)#sectorSize_str[1]
    minerPowerDict = get_master_proving_info_fromDB(miner_list)#sectorSize_str[1]
    for i in miner_list:
        if(i in sizeDict.keys()):
            #### 单位化成G
            sectorSize = int(sizeDict[i][0])/(1024*1024*1024)
        else:
            #### 不在表中则默认用64G
            print_red("矿工号不在数据库的表中, minerID: ",i)
            sectorSize = 64
        ### master实际一天增加的算力值,单位是T
        powerGain=minerPowerDict[i]*int(sectorSize)/1024.0
        cmd_pre_commit_sum="""awk '/%s/ {sum += $10};END {print sum}'  slave_info.txt"""% i
        cmd_slave_count="""cat slave_info.txt | grep %s|awk '{print $4}' |wc -l"""% i
        cmd_proving_sum="""awk '/%s/ {sum += $14};END {print sum}'  slave_info.txt"""% i
        cmd_final_count="""awk '/%s/ {sum += $12};END {print sum}'  slave_info.txt"""% i
        pre_commit_sum = float(os.popen(cmd_pre_commit_sum).read().rstrip())
        slave_count= int(os.popen(cmd_slave_count).read().rstrip())
        proving_sum =float(os.popen(cmd_proving_sum).read().rstrip())
        final_count =float(os.popen(cmd_final_count).read().rstrip())
        total_daily_speed_per_day=pre_commit_sum*int(sectorSize)/1024.0
        slave_avg_speed_per_hour=pre_commit_sum*int(sectorSize)/(slave_count*24)
        slave_avg_speed_per_day=pre_commit_sum*int(sectorSize)/(slave_count*1024)
        result_data=[i,slave_count,pre_commit_sum,proving_sum,final_count,round(total_daily_speed_per_day,2),round(slave_avg_speed_per_hour,2),round(slave_avg_speed_per_day,2),round(powerGain,2)]
        list_cmd.append(result_data)
    return list_cmd

def get_miner_sector_size(miner_list):
    miner_list_str = []
    for i in miner_list:
        i = "\"" + i + "\""
        miner_list_str.append(i)
    miner_list_str = ",".join(miner_list_str)

    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    cur = conn.cursor()  # 获取游标
    # 另一种插入数据的方式，通过字符串传入值
    sql = "select miner_address,sector_size,tag_name from dwm.t_lotus_node where miner_address in (%s)"%miner_list_str
    print_blue("查询数据库获取miner sector size: ",sql)
    cur.execute(sql)
    result = cur.fetchall()
    print_yellow(result)
    result=[list(x) for x in result]
    miner_info_dict = {}
    for i in result:
        miner_info_dict[i[0]] = [i[1],i[2]]

    cur.close()
    conn.close()
    return miner_info_dict


def master_info(data_dict):
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    #print(data_dict)

    cur = conn.cursor()  # 获取游标

    # 另一种插入数据的方式，通过字符串传入值
    sql = "insert into tr_slave_speed values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    cur.execute(sql, (
        data_dict["date_run_time"],
        data_dict["miner_id"],
        data_dict["slave_num"],
        data_dict["pre_sectors_total_num"],
        data_dict["proving_sectors_total_num"],
        data_dict["final_sectors_total_num"],
        data_dict["total_daily_speed_per_day"],
        data_dict["slave_avg_speed_per_hour"],
        data_dict["slave_avg_speed_per_day"],
        data_dict["master_proving_per_day"]
    ))

    conn.commit()
    cur.close()
    conn.close()

def get_master_proving_info_fromDB(minerID_list):
    import time
    import datetime
    # 今天日期
    today = datetime.date.today()
    # 昨天时间
    yesterday = today - datetime.timedelta(days=1)
    # 昨天开始时间戳
    yesterday_start_time = int(time.mktime(time.strptime(str(yesterday), '%Y-%m-%d')))
    # 昨天结束时间戳
    yesterday_end_time = int(time.mktime(time.strptime(str(today), '%Y-%m-%d'))) - 1

    url_base = """http://192.168.1.14:9090/api/v1/query?query=SectorStateProving{instance=~'.*19402'}&time="""

    # 获取昨天开始时间的miner的proving个数
    url_start = url_base + str(yesterday_start_time)
    miner_provingnum_dict_start = {}
    result = requests.get(url_start).text
    json_str = json.loads(result)
    tmp_list = json_str["data"]["result"]
    for i in tmp_list:
        m_id = i["metric"]["name"]
        p_num = i["value"][1]
        miner_provingnum_dict_start[m_id] = int(p_num)
    print_blue("昨天初始的矿工的proving个数为: ",miner_provingnum_dict_start)
    # 获取昨天结束时间的miner的proving个数
    url_end = url_base + str(yesterday_end_time)
    miner_provingnum_dict_end = {}
    result2 = requests.get(url_end).text
    json_str2 = json.loads(result2)
    tmp_list2 = json_str2["data"]["result"]
    for i in tmp_list2:
        m_id = i["metric"]["name"]
        p_num = i["value"][1]
        miner_provingnum_dict_end[m_id] = int(p_num)
    print_blue("昨天结束的矿工的proving个数为: ",miner_provingnum_dict_end)

    # 计算24小时每个miner的算力增长
    miner_power_dict={}
    for i in minerID_list:
        if(i not in miner_provingnum_dict_end.keys()):
            print_red("普罗米修斯的数据库中查不到昨日矿工的proving个数信息, minerID: ",i)
            miner_power_dict[i]=-1
            continue
        if(i not in miner_provingnum_dict_start.keys() and i in miner_provingnum_dict_end.keys()):
            print_red("普罗米修斯的数据库中查不到昨日开始时矿工的proving个数信息,但是可以查到昨日结束时的信息 minerID: ",i)
            miner_power_dict[i]=miner_provingnum_dict_end[i]
            continue
        miner_power_dict[i]=miner_provingnum_dict_end[i] - miner_provingnum_dict_start[i]
        print_blue("矿工 ",i," 昨天一天的proving扇区增加个数为 ",miner_power_dict[i])
    return miner_power_dict


if __name__ == '__main__':
    print_date("------------ start caculate slave speed ---------------")
    info_data=get_slave_speed()
    dbDataDict = {}
    for i in range(len(info_data)):

        dbDataDict["date_run_time"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        dbDataDict["miner_id"] = info_data[i][0]
        dbDataDict["slave_num"] = info_data[i][1]
        dbDataDict["pre_sectors_total_num"] = info_data[i][2]
        dbDataDict["proving_sectors_total_num"] = info_data[i][3]
        dbDataDict["final_sectors_total_num"] = info_data[i][4]
        dbDataDict["total_daily_speed_per_day"] = info_data[i][5]
        dbDataDict["slave_avg_speed_per_hour"] = info_data[i][6]
        dbDataDict["slave_avg_speed_per_day"] = info_data[i][7]
        dbDataDict["master_proving_per_day"] = info_data[i][8]
        master_info(dbDataDict)