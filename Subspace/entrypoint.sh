#!/bin/bash
cd /subspace || return


nohup ./start_farmer.sh  ${SUBSPACE_WALLET}  > /data/subspace/farmer.log 2>&1 &

./node \
  --chain gemini-2a \
  --base-path /data/subspace \
  --execution wasm \
  --pruning 1024 \
  --keep-blocks 1024 \
  --port 30333 \
  --rpc-cors all \
  --rpc-methods safe \
  --unsafe-ws-external \
  --validator \
  --in-peers 120 \
  --in-peers-light 150 \
  --out-peers 120 \
  --reserved-only \
  --reserved-nodes="/ip4/172.80.8.31/tcp/30333/p2p/12D3KooWDmErmRyC8GGRMfpsWhXQ8RXhSHCvmqDckHauzrLZ1Yww" \
  --reserved-nodes="/ip4/115.231.82.193/tcp/30333/p2p/12D3KooWNNVerDR1mk4dvsr5f5kT7t6BZCwcHZ9MKgdzbW1Yougy" \
  --name ${SUBSPACE_NODENAME}