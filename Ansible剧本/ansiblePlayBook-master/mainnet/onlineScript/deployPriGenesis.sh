#!/usr/bin/env bash
### setsid ~/bin/lotus daemon  --bootstrap=false  --genesis=devnet.car > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
### setsid ~/bin/lotus-miner run --nosync > ~/log/lotus-power.`date +"%m%d%H%M"`.out 2>&1 &
set -x
export RUST_BACKTRACE=full
export RUST_LOG=info
NUM_SECTORS=4
SECTOR_SIZE=536870912  #8M
genesisPath="/home/filecoin/genesis-sectors"
templateFile="/home/filecoin/genesis-sectors/localnet.json"
### clean env
kill `ps -u $USER -f | grep "lotus" | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
~/bin/view_lotus.sh cleanEnv
rm -rf ${genesisPath}

~/bin/lotus-seed pre-seal --miner-addr=t01000 --sector-offset=0 --sector-size=${SECTOR_SIZE} --num-sectors=${NUM_SECTORS}
~/bin/lotus-seed genesis new ${templateFile}
sed -i 's/"Balance":.*/"Balance": "1000000000000000000000",/g' ${templateFile}
~/bin/lotus-seed genesis add-miner ${templateFile} ~/.genesis-sectors/pre-seal-f01000.json
###上面的跑一次就够了,生成的文件可以反复利用,保存在genesisPath和templateFile 


### start daemon
setsid ~/bin/lotus daemon --lotus-make-genesis="/home/filecoin/bin/devnet.car" --genesis-template=${templateFile} --bootstrap=false > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
sleep 15

~/bin/lotus wallet import ~/genesis-sectors/pre-seal-t01000.key
walletDefault=`~/bin/lotus wallet list`
~/bin/lotus wallet set-default ${walletDefault}

### init miner
~/bin/lotus-miner init --genesis-miner --actor=t01000 --sector-size=${SECTOR_SIZE} --pre-sealed-sectors=~/genesis-sectors --pre-sealed-metadata=~/genesis-sectors/pre-seal-t01000.json --nosync
### start miner
setsid ~/bin/lotus-miner run --nosync > ~/log/lotus-power.`date +"%m%d%H%M"`.out 2>&1 &

kill `ps -u $USER -f | grep "python" | grep 8989 | grep -v grep | awk '{print $2}'` 2> /dev/null
cd ~/bin; nohup python3 -m http.server 8989 &
kill `ps -u $USER -f | grep "fountain" | grep -v grep | awk '{print $2}'` 2> /dev/null
setsid ~/bin/fountain --repo=~/.lotus run --from=${walletDefault} --front=0.0.0.0:9292 > ~/log/foutain.`date +"%m%d%H%M"`.out 2>&1 &