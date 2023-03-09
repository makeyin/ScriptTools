#!/bin/bash
#Usage: */10 * * * *  cd /home/devnet; ./netconnect.sh >> netconnect.log

echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to net connect other peers ============ "
peers="
/dns4/bootstrap-0.ipfsmain.cn/tcp/34721/p2p/12D3KooWQnwEGNqcM2nAcPtRR9rAX8Hrg4k9kJLCHoTR5chJfz6d
/dns4/bootstrap-7.mainnet.filops.net/tcp/1347/p2p/12D3KooWRs3aY1p3juFjPy8gPN95PEQChm2QKGUCAdcDCC4EBMKf
"
for i in $peers
do
    ~/bin/lotus net connect  $i
done