# coding=utf-8
##### 安装依赖库: pip3 install pymysql==0.10.1  -i https://pypi.tuna.tsinghua.edu.cn/simple/
##### crontab任务设置： 09 * * * * cd /home/devnet/autoBalance/allMiner;python3 checkMoney.py >> checkMoney.log
import json
import os, sys
import time
from datetime import datetime, timedelta
import numpy as np
import requests
from influxdb import InfluxDBClient

def getBaseFeeFromDB():
    cmd_24h = """ select * from "chain.basefee" ORDER BY time DESC limit 2880 """
    result = client.query(cmd_24h)
    values = result.raw['series'][0]['values']
    #print(len(values))
    #print(type(values))
    baseFeeList = [i[1] for i in values]
    v25_24h = format(np.percentile(baseFeeList, 25), '.20f')
    v33_24h = format(np.percentile(baseFeeList, 33), '.20f')
    v40_24h = format(np.percentile(baseFeeList, 40), '.20f')
    v50_24h = format(np.percentile(baseFeeList, 50), '.20f')
    v66_24h = format(np.percentile(baseFeeList, 66), '.20f')
    avg_24h = format(np.average(baseFeeList), '.20f')

    cmd_4h = """ select * from "chain.basefee" ORDER BY time DESC limit 480 """
    result = client.query(cmd_4h)
    values = result.raw['series'][0]['values']
    #print(len(values))
    #print(type(values))
    baseFeeList = [i[1] for i in values]
    v25_4h = format(np.percentile(baseFeeList, 25), '.20f')
    v40_4h = format(np.percentile(baseFeeList, 40), '.20f')
    v50_4h = format(np.percentile(baseFeeList, 50), '.20f')
    v66_4h = format(np.percentile(baseFeeList, 66), '.20f')
    avg_4h = format(np.average(baseFeeList), '.20f')

    cmd_1h = """ select * from "chain.basefee" ORDER BY time DESC limit 120 """
    result = client.query(cmd_1h)
    values = result.raw['series'][0]['values']
    baseFeeList = [i[1] for i in values]
    v25_1h = format(np.percentile(baseFeeList, 25), '.20f')
    v40_1h = format(np.percentile(baseFeeList, 40), '.20f')
    v50_1h = format(np.percentile(baseFeeList, 50), '.20f')
    v66_1h = format(np.percentile(baseFeeList, 66), '.20f')
    v80_1h = format(np.percentile(baseFeeList, 80), '.20f')
    avg_1h = format(np.average(baseFeeList), '.20f')

    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"--------------- Start calculate base fee")
    print(float(avg_4h)*1000000000)
    print ("avg_24h： ", float(avg_24h)*1000000000)
    print ("avg_4h： ", float(avg_4h)*1000000000)
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    cur = conn.cursor()
    sql = "insert into tr_basefee_avg values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    cur.execute(sql, (
        datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        v25_24h,
        v33_24h,
        v40_24h,
        v50_24h,
        v66_24h,
        avg_24h,
        v25_4h,
        v40_4h,
        v50_4h,
        v66_4h,
        avg_4h,
        v25_1h,
        v40_1h,
        v50_1h,
        v66_1h,
        v80_1h,
        avg_1h,
    ))

    conn.commit()
    cur.close()
    conn.close()


if __name__ == '__main__':
  ######################################
  minerConfFileList = []

  #首先连接influxdb
  client = InfluxDBClient(host='10.10.8.7',port=18086,username='',password='',ssl=False,verify_ssl=False,database='lotus')
  getBaseFeeFromDB()