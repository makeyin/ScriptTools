#!/bin/bash
startTryNum=1
while [ $startTryNum -lt 80 ]
do
    kill -9 `ps -u $USER -f | grep lotus-slave-miner | grep -v grep | awk '{print $2}'` 2> /dev/null
    kill -9 `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null
    rm -f ~/.lotusslave  && rm -f ~/.lotusposter
    sleep 1
    ~/bin/lotus-slave-miner init
    sleep 5
    ~/bin/lotus-poster init
    sleep 5
    sed -i 's/BootstrapPeers = []/BootstrapPeers = ["/ip4/58.215.176.11/tcp/7000/p2p/12D3KooWD8F3rJy4LGTc3h2P1GnyV4HoJiVQQUM8cXEWnmHCo2pP"]/g' /home/devnet/.lotusposter/config.toml
    sed -i 's/GroupName = []/GroupName = "wx110427"/g'  /home/devnet/.lotusposter/config.toml
    sed -i 's/BootstrapPeers = []/BootstrapPeers = ["/ip4/58.215.176.11/tcp/7000/p2p/12D3KooWD8F3rJy4LGTc3h2P1GnyV4HoJiVQQUM8cXEWnmHCo2pP"]/g ' /home/devnet/.lotusslave/config.toml
    sed -i 's/GroupName = []/GroupName = "wx110427"/g'  /home/devnet/.lotusslave/config.toml
    sed -i 's/GroupName = []/GroupName = "wx110427"/g'
    ~/bin/view_lotus.sh poster
    sleep 1m
    ~/bin/view_lotus.sh slave
    sleep 5m
    echo `date +'%Y-%m-%d %H:%M:%S'` " 搭建第: $startTryNum 次" >> sectorsID.txt
    ~/bin/view_lotus.sh logs | grep -E "sidsc/sector_id_counter.go:" >> sectorsID.txt
    let startTryNum++
    sleep
done


