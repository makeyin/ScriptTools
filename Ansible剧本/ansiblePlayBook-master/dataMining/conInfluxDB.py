from influxdb import InfluxDBClient
import datetime

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
    print(json_body)
    client.write_points(json_body,time_precision='m') # 写入数据


# 首先连接influxdb
client = InfluxDBClient(host='192.168.100.6',port=8086,username='admin',password='admin',ssl=False,verify_ssl=False,database='lotus')

# 创建数据库
#client.create_database('lotus')   
# 查询数据库
print(client.get_list_database())
# 显示数据库中的表
result = client.query('show measurements;') 
print("Result: {0}".format(result))

# 写数据
timestamp = datetime.datetime.now()

from datetime import datetime, timedelta
 
now_time = datetime.now()
 
utc_time = now_time - timedelta(hours=8)              # UTC只是比北京时间提前了8个小时
 
utc_time = utc_time.strftime("%Y-%m-%dT%H:%M:%SZ")    # 转换成Aliyun要求的传参格式...

writeChainMiningStatusToInfluxDB(utc_time, "t018985","37.6392%","84.79%","81.25%","95.82%")

# # 读数据
# selectMinerCmd = """SELECT top("value", "miner", 20) as "power" FROM "chain.miner_power" WHERE time >= now() - 10m"""
# result = client.query(selectMinerCmd)
# print("=========")
# #for i in result.items():
# #    print(i[1]['time'])
# values = result.raw['series'][0]['values']
# minerIDList=[]
# for miner in values:
#     minerIDList.append(miner[2])
# print(minerIDList)

#print("Result: {0}".format(result))


#### 删除表
client.drop_measurement('data.ChainMiningStatus')