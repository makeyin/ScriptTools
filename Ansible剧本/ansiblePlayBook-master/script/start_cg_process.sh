#!/bin/bash
# Usage: 用root跑  nohup bash start_cg_process.sh /home/devnet/bin/start_cg_process.sh
set -x
pid=$$
exec_cmd="${@:1}"

cpu_set="1-35"
mem_node=0
sudo bash -c "echo $mem_node > /sys/fs/cgroup/cpuset/norm_prior/cpuset.mems"
sudo bash -c "echo $cpu_set > /sys/fs/cgroup/cpuset/norm_prior/cpuset.cpus"
sudo bash -c "echo $pid > /sys/fs/cgroup/cpuset/norm_prior/tasks"
export LOTUS_SLAVE_PATH="/home/devnet/.lotusslave"
setsid /home/devnet/bin/lotus-slave-miner run > /home/devnet/log/slave-miner.`date +"%m%d%H%M"`.out 2>&1 &