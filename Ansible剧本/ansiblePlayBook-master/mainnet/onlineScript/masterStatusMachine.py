
# minerID=$(grep provider ~/log/`ls -lt ~/log | awk '{print \$NF}' | grep lotus-power | head -1` | head -1 | awk  -F'"' '{print $4}')
# sleep 10
# echo "---------------------------------------  MinerID:${minerID}  --------------------------------------------------------"
# stateMachine=`curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#" | grep -v " 0" | awk -F "State" '{print \$2}' | awk '{printf"%s ",\$0}'`
# message=`~/bin/lotus mpool stat --local | awk -F "Nonce" '{print \$2}' | head -1`
# sleep 10
# bafflePlate=`grep "EnableManualPreCommitOnChain"  ~/.lotusminer/config.toml|awk -F "=" '{print \$2}'`
# MaxSealTotal=`grep "MaxSealTotal" ~/.lotusminer/config.toml |awk -F "=" '{print \$2}'`
# slaveCount=$(grep  "/fil/proxy/relation/" ~/log/`ls -lt ~/log | awk '{print \$NF}' | grep lotus-power | head -1` | awk 'END {print}' |cut -d ':' -f6|cut -d '}' -f1)
# echo 各阶段状态数:${stateMachine}
# echo 消息量:${message}
# echo 是否开启挡板:${bafflePlate}  MaxSealTotal:${MaxSealTotal}   slave数量:${slaveCount}
import os


def get_All_info():
    getStateMachineCmd="""curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#" | grep -v " 0" | awk -F "State" '{print \$2}' | awk '{printf"%s ",\$0}'"""
    getMinerIDCmd="""grep provider ~/log/`ls -lt ~/log | awk '{print \$NF}' | grep lotus-power | head -1` | head -1 | awk  -F'"' '{print $4}'"""
    getMessagePollCmd="""~/bin/lotus mpool stat --local | awk -F "Nonce" '{print \$2}' | head -1"""
    getBafflePlateCmd="""grep "EnableManualPreCommitOnChain"  ~/.lotusminer/config.toml| grep -v "#"|awk -F "=" '{print \$2}'"""
    getMaxSealTotalCmd="""grep "MaxSealTotal" ~/.lotusminer/config.toml | grep -v "#"|awk -F "=" '{print \$2}'"""
    getSlaveCountCmd="""grep  "/fil/proxy/relation/" ~/log/`ls -lt ~/log | awk '{print \$NF}' | grep lotus-power | head -1` | awk 'END {print}' |cut -d ':' -f6|cut -d '}' -f1"""
    StateMachineCmd = os.popen(getStateMachineCmd).read().rstrip()
    MinerIDCmd = os.popen(getMinerIDCmd).read().rstrip()
    MessagePollCmd = os.popen(getMessagePollCmd).read().rstrip()
    BafflePlateCmd = os.popen(getBafflePlateCmd).read().rstrip()
    MaxSealTotalCmd = os.popen(getMaxSealTotalCmd).read().rstrip()
    SlaveCountCmd = os.popen(getSlaveCountCmd).read().rstrip()
    data_result = {"StateMachine":StateMachineCmd,"MinerID":MinerIDCmd,"MessagePoll":MessagePollCmd,"BafflePlate":BafflePlateCmd,"MaxSealTotal":MaxSealTotalCmd,"SlaveCount":SlaveCountCmd}
    return data_result

def DataToDB(data_dict):
    print(data_dict)
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    tableName = "tr_upload_qiniu"
    cur = conn.cursor()

    sql = "insert into miner_lucky_value_statistics values(%s,%s,%s,%s,%s,%s,%s)"

    cur.execute(sql, (
        data_dict["miner_id"],

    ))
    conn.commit()
    cur.close()
    conn.close()

if __name__ == '__main__':
    dbDataDict = {}
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

    info=get_All_info()
    dbDataDict["miner_id"] = info["minerID"]
    dbDataDict["sectors_all_count"] = int(info["AllSector"])
    dbDataDict["date_run_time"] = info["dataTime"]
    dbDataDict["uploads_count"] = int(info["isuploads"])
    dbDataDict["notupload_slave_count"] = int(info["UploadSlave"])
    dbDataDict["notupload_count"] = int(info["isFinish"])
    dbDataDict["proportion"] = '%s%%'%round((int(info["isuploads"])/int(info["AllSector"]))*100,2)
    DataToDB(dbDataDict)