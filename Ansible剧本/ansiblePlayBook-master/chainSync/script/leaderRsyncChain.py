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
                backDataReader = os.popen("ls -al /tmp/ChainData_Backup/badger/ | grep -e log -e sst | awk -F' ' '{print $NF}'")
                backData = backDataReader.read().rstrip().split("\n")
                print(backData)
                newDataReader = os.popen("ls -al /home/%s/.filecoin/badger_bak/ | grep -e log -e sst | awk -F' ' '{print $NF}'"%miner_user)
                newData = newDataReader.read().rstrip().split("\n")
                print(newData)
                # calculate filename in newData but not in backData
                needCopy = list(set(backData).difference(set(newData)))
                print(needCopy)
                if(needCopy != []):
                    for f in needCopy:
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: copy badger file to .filecoin/badger_bak/, filename: ",f)
                        os.system("rsync -rvzuP  --delete  /tmp/ChainData_Backup/badger/%s /home/%s/.filecoin/badger_bak/"%(f,miner_user))
                else:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: badger files are all the same")
                ### copy chain
                backChainReader = os.popen("ls -al /home/%s/.filecoin/chain_bak/ | grep -e log -e sst | awk -F' ' '{print $NF}'"%miner_user)
                backChain = backChainReader.read().rstrip().split("\n")
                print(backChain)
                newChainReader = os.popen("ls -al /tmp/ChainData_Backup/chain/ | grep -e log -e sst | awk -F' ' '{print $NF}'")
                newChain = newChainReader.read().rstrip().split("\n")
                print(newChain)
                # calculate filename in newChain but not in backChain
                needCopyChain = list(set(backChain).difference(set(newChain)))
                print(needCopyChain)
                if(needCopyChain != []):
                    for f in needCopyChain:
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: copy chain file to .filecoin/chain_bak/, filename: ",f)
                        os.system("rsync -rvzuP  --delete  /tmp/ChainData_Backup/chain/%s /home/%s/.filecoin/chain_bak/"%(f,miner_user))
                else:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: chain files are all the same")
            except Exception as e:
                print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"FATAL: error occured: ",e)
                            #result = r.text
            #print(result)
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," INFO: going to sleep",flush = True)
            time.sleep(3600)
if __name__ == '__main__':
    fire.Fire()