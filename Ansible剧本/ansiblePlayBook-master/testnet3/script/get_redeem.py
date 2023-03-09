####crontab job cmd:   */5 * * * *  python3 ~/get_redeem_msg.py >> ~/redeem_msg.log
import os,time
cmd = "~/bin/lotus-storage-miner rewards list"
get_rewards_cmd ="~/bin/lotus-storage-miner rewards redeem"
data=os.popen(cmd).read().rstrip()
print("data is: ",data)
#print(type(data))
if (data!=""):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### begin to send redeem msg")
    os.popen(get_rewards_cmd).read().rstrip()