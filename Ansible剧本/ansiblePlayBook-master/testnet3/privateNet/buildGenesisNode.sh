#!/bin/bash
hostfile=$1
downLoadBinUrl=$2
cd /home/ansible/ansiblePlayBook/lotus/testnet3/privateNet
rm -f geneNodePB.retry
ansible-playbook geneNodePB.yml -i $hostfile -e "downloadGenesisBinUrl=$2 minerUser=devnet" || true

if [ -f "geneNodePB.retry" ]; then
  ansible-playbook geneNodePB.yml -i $hostfile -e "downloadGenesisBinUrl=$2 minerUser=devnet" --limit @geneNodePB.retry
fi