#!/bin/bash
function f0111007{
  hour=$2
  ssh -t -p 45823 devnet@10.10.8.207 << eeooff
  export FULLNODE_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.3KQBQPMDApKu2_TrYq3dLYonxW2Sf44fbQ6NC3m2Wag:/ip4/10.10.8.235/tcp/1234/http
  ~/bin/view_lotus.sh check $hour
eeooff
}


function slave{
        slaveIP=$2
        sectors=$3
        ssh -t -p 45823 filecoin@$slaveIP << eeooff
        ~/bin/lotus-slave-miner sectors status $sectors |grep "Status:"
eeooff
}


case "$1" in
  f0111007)
       f0111007
       ;;
  slave)
       ssh -t -p 45823 filecoin@$slaveIP << eeooff
       ~/bin/lotus-slave-miner sectors status $sectors |grep "Status:"
eeooff
       ;;  
  *)
esac




