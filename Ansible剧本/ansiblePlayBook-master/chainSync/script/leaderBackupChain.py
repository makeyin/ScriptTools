import fire
import os
import time


class BackupChain(object):

    def leader_back_chain(self, miner_user):
        var = 1
        while var == 1 :  # 该条件永远为true，循环将无限执行下去
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: ------- start to check back up chain data：")

            try:
                ### copy badger
                newDataReader = os.popen("ls -al  /home/%s/.filecoin/badger/ |grep -E '(vlog|sst)' | awk  '{print $NF}'"%miner_user)
                newData = newDataReader.read().rstrip().split("\n")
                backDataReader = os.popen("ls -al /tmp/ChainData_Backup/badger/ | awk -F' ' '{print $NF}'")                
                backData = backDataReader.read().rstrip().split("\n")
                # calculate filename in newData but not in backData
                needCopy = list(set(newData).difference(set(backData)))
                if(needCopy != []):
                    for f in needCopy:                        
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: copy badger file to /tmp/ChainData_Backup/badger/, filename: ",f)
                        os.system("rsync -rvzuP  --delete  /home/%s/.filecoin/badger/%s /tmp/ChainData_Backup/badger"%(miner_user,f))
                else:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: badger files are all the same")

                ### copy chain
                newChainReader = os.popen("ls -al  /home/%s/.filecoin/chain/ |grep -E '(vlog|sst)' | awk  '{print $NF}'"%miner_user)
                newChain = newChainReader.read().rstrip().split("\n")
                backChainReader = os.popen("ls -al /tmp/ChainData_Backup/chain/  | awk -F' ' '{print $NF}'")                
                backChain = backChainReader.read().rstrip().split("\n")
                # calculate filename in newChain but not in backChain
                needCopyChain = list(set(newChain).difference(set(backChain)))                
                if(needCopyChain != []):
                    for f in needCopyChain:                        
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: copy chain file to /tmp/ChainData_Backup/chain/, filename: ",f)
                        os.system("rsync -rvzuP  --delete /home/%s/.filecoin/chain/%s /tmp/ChainData_Backup/chain"%(miner_user,f))                
                else:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: chain files are all the same")

            except Exception as e:
                print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"FATAL: error occured: ",e)

            #result = r.text
            #print(result)
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: going to sleep",flush = True)
            time.sleep(1800)

if __name__ == '__main__':
    fire.Fire()