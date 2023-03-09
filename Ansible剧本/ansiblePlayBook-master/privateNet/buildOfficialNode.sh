#!/bin/bash
hostfile=$1
downLoadBinUrl=$2
cd /home/ansible/ansiblePlayBook/lotus/privateNet

rm -f officialNodePB.retry
ansible-playbook officialNodePB.yml -i $hostfile -e "downloadGenesisBinUrl=$2 minerUser=devnet" || true

if [ -f "officialNodePB.retry" ]; then
  ansible-playbook officialNodePB.yml -i $hostfile -e "downloadGenesisBinUrl=$2 minerUser=devnet" --limit @officialNodePB.retry
fi