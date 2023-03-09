#!/usr/bin/env bash
set -x
export RUST_BACKTRACE=full
export RUST_LOG=info
export TRUST_PARAMS=1
export LOTUS_IGNORE_DRAND=_yes_
export OPTION20=true
export OPTION12=true
export OPTION14=10
export OPTION18=/home/${USER}/vde/
export OPTION1=false
export OPTION3=9
export OPTION4=true
export OPTION5=true
export OPTION6=[0,1,2,3]
export OPTION7=10000
export OPTION8=true
export OPTION9=1
export OPTION10=0
export OPTION11=false
export OPTION17=0
export OPTION15=0
export OPTION22=None
NUM_SECTORS=4
SECTOR_SIZE=536870912
genesisPath="/home/${USER}/genesis-sectors"
templateFile="/home/${USER}/genesis-sectors/localnet.json"

### clean env
kill `ps -u $USER -f | grep "lotus" | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
~/bin/view_lotus.sh cleanEnv
#rm -rf ${genesisPath}

if [ ! -d ${genesisPath} ];then
    ###以下跑一次就够了,生成的文件可以反复利用,保存在genesisPath
    ~/bin/lotus-seed --sector-dir="${genesisPath}" pre-seal --miner-addr=t01000 --sector-offset=0 --sector-size=${SECTOR_SIZE} --num-sectors=${NUM_SECTORS}
    ~/bin/lotus-seed genesis new ${templateFile}
    ~/bin/lotus-seed genesis add-miner ${templateFile} ${genesisPath}/pre-seal-t01000.json
    sed -i 's/"Balance":.*/"Balance": "600000000000000000000000000",/g' ${templateFile}
fi

### start daemon
rm -f /home/devnet/bin/devnet.car
setsid ~/bin/lotus daemon --lotus-make-genesis="/home/testnet/bin/devnet.car" --genesis-template=${templateFile} --bootstrap=false > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
sleep 15

~/bin/lotus wallet import ${genesisPath}/pre-seal-t01000.key
walletDefault=`~/bin/lotus wallet list`
~/bin/lotus wallet set-default ${walletDefault}

### init miner
~/bin/lotus-storage-miner init --genesis-miner --actor=t01000 --sector-size=${SECTOR_SIZE} --pre-sealed-sectors=${genesisPath} --pre-sealed-metadata=${genesisPath}/pre-seal-t01000.json --nosync
### start miner
sed -i 's/MinerMode =.*/MinerMode = "normal"/g' ~/.lotusstorage/config.toml
setsid ~/bin/lotus-storage-miner run --nosync > ~/log/storage-miner.`date +"%m%d%H%M"`.out 2>&1 &

kill `ps -u $USER -f | grep "python" | grep 8989 | grep -v grep | awk '{print $2}'` 2> /dev/null
cd ~/bin; nohup python3 -m http.server 8989 &
kill `ps -u $USER -f | grep "fountain" | grep -v grep | awk '{print $2}'` 2> /dev/null
setsid ~/bin/fountain --repo=~/.lotus run --from=${walletDefault} --front=0.0.0.0:9292 > ~/log/foutain.`date +"%m%d%H%M"`.out 2>&1 &