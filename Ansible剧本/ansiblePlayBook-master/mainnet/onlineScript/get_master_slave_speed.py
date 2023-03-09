import re
import socket
from datetime import datetime, timedelta
import os
import argparse
def merge_log(startTime):
    try:
        os.remove("/home/filecoin/log/lotus_slave_log")
    except Exception as a:
        pass
    mlogFile_cmd = os.popen(
        "ls -altr ~/log | grep  slave|grep -v lotus_slave_log | grep -v get_master_slave_speed | awk '{print $9}'").read().rstrip()
    logFile_list = mlogFile_cmd.split("\n")
    merge_cmd = """cat ~/log/%s  >> ~/log/lotus_slave_log""" % (logFile_list[-1])
    os.popen(merge_cmd).read().rstrip()
    i = len(logFile_list)-1
    while True:
        i-= 1
        log_starTime = os.popen(
            """grep --text  '^2021' --text ~/log/lotus_slave_log|awk -F "." '{print $1}' |head -1""").read().rstrip()
        if log_starTime > startTime :
            if i < 0:
                break
            merge_cmd = """sed -ne '1 r /home/filecoin/log/%s' -e '1N;P'  -i /home/filecoin/log/lotus_slave_log""" % (logFile_list[i])
            os.popen(merge_cmd).read().rstrip()
        else:
            break


def get_salve_info(startTime,endTime,hour_interval):
    cmd_size="""ls -lrh ~/.lotusslave/sealed |tail -1 |awk  '{print $5}' |awk -F "G" '{print $1}'"""
    merge_log(startTime)
    logFile = "lotus_slave_log"
    sector_size=int(os.popen(cmd_size).read().rstrip())
    import time
    time.sleep(3)
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    cmd_preCommit1Count = """grep  "SealPreCommit1 Finished" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk '{print $8}'|awk -F '"' '{print $2}' |sort -n|uniq  |wc -l""" % (logFile, startTime, endTime)
    cmd_PreCommit2Count = """grep  "SealPreCommit2 Finished" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk '{print $8}'|awk -F '"' '{print $2}' |sort -n|uniq  |wc -l""" % (logFile, startTime, endTime)
    cmd_Commit1Count = """grep  "SealCommit1 Finished" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk '{print $8}'|awk -F '"' '{print $2}' |sort -n|uniq  |wc -l""" % (logFile, startTime, endTime)
    cmd_ProvingCount = """grep  "updated state to Proving" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk '{print $8}' |sort -n |uniq |wc  -l""" % (logFile, startTime, endTime)
    Cmd_minerID="""grep --text  "/fil/proxy/relation/"  lotus_slave_log |head -1 |awk -F "/" '{print $6}' |awk -F "power" '{print $1}'"""

    cmd_FinalCount = """grep  "Manager FinalizeSector finished" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk -F '[""]' '{print $4}' |sort -n |uniq |wc -l""" % (logFile, startTime, endTime)
    preCommit1Count = int(os.popen(cmd_preCommit1Count).read().rstrip())*sector_size/int(hour_interval)
    PreCommit2Count = int(os.popen(cmd_PreCommit2Count).read().rstrip())*sector_size/int(hour_interval)
    PreCommitSectorTotal =  int(os.popen(cmd_PreCommit2Count).read().rstrip())

    Commit1Count = int(os.popen(cmd_Commit1Count).read().rstrip())*sector_size/int(hour_interval)
    ProvingCount = int(os.popen(cmd_ProvingCount).read().rstrip())*sector_size/int(hour_interval)
    minerID = os.popen(Cmd_minerID).read().rstrip()
    FinalCount = os.popen(cmd_FinalCount).read().rstrip()
    print("minerID:",minerID," slave_ip:",ip," pre1:",round(preCommit1Count,2)," pre2:",round(PreCommit2Count,2)," sectorTotal:",PreCommitSectorTotal,"sectorFinalCount:",FinalCount,"provingCount:",round(ProvingCount,2))
    #print("minerID:",minerID,"slave_ip:",ip,"pre1:",round(preCommit1Count,2),"pre2:",round(PreCommit2Count,2),"Commit1:",round(Commit1Count,2),"Proving:",round(ProvingCount,2))

def get_master_info(startTime,endTime,hour_interval):
    mlogFile_cmd = os.popen(
        "ls -altr ~/log | grep  lotus-power|grep -v lotus-power-log|tail -n 2 | awk '{print $9}'").read().rstrip()
    logFile_list = mlogFile_cmd.split("\n")
    merge_cmd = """cat ~/log/%s ~/log/%s > ~/log/lotus-power-log""" % (logFile_list[0], logFile_list[1])
    logFile = "lotus-power-log"
    os.popen(merge_cmd).read().rstrip()
    cmd_precommitted = """grep  "precommitted StateWaitMsg" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'| awk '{print $9}' |awk -F '"' '{print $2}' |sort -n |uniq |wc -l""" % (logFile, startTime, endTime)
    cmd_submitcommit = """grep  "Sector commit Committed" --text ~/log/%s  |  awk '{if($1>"%s" && $1<"%s")print $0}'|awk '{print $9}' |awk -F '"' '{print $2}' |sort -n|uniq  |wc -l""" % (logFile, startTime, endTime)
    precommittedCount = os.popen(cmd_precommitted).read().rstrip()
    submitcommitCount = os.popen(cmd_submitcommit).read().rstrip()

    print("24hPre:",    precommittedCount,    "24hproving",submitcommitCount)

def get_star_end_time():
    import datetime
    today = datetime.datetime.today()
    star_time = (datetime.datetime(today.year, today.month, today.day, 0, 0, 0) + datetime.timedelta(days=-1)).strftime(
        "%Y-%m-%dT%H:%M:%S")
    end_time = datetime.datetime(today.year, today.month, today.day, 0, 0, 0).strftime("%Y-%m-%dT%H:%M:%S")

    time=[star_time,end_time]
    return time
if __name__ == '__main__':
    time=get_star_end_time()
    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--startTime', default=time[0], type=str)
    parser.add_argument('--endTime', default=time[1], type=str)
    parser.add_argument('--hour', default=0, type=int)
    parser.add_argument('--min', default=0, type=int)
    parser.add_argument('--lotusName',  type=str)
    args = parser.parse_args()
    startTime = args.startTime
    endTime = args.endTime
    hour_interval = args.hour
    min_interval = args.min
    lotus_name = args.lotusName
    if lotus_name == None:
        print("请输入：power & slave")
        exit(0)
    if (hour_interval != 0 or min_interval != 0):
        min_interval = min_interval
        startTime = (datetime.now() - timedelta(hours=hour_interval, minutes=min_interval)).strftime(
            "%Y-%m-%dT%H:%M:%S")
        endTime = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        startTime = startTime[:-2] + "00"
        endTime = endTime[:-2] + "00"
    if hour_interval == 0:
        hour_interval = 24
    if lotus_name == "slave":
        get_salve_info(startTime,endTime,hour_interval)
    elif lotus_name == "power":
        get_master_info(startTime,endTime,hour_interval)
    else:
        print(" input --lotusName salve & power")