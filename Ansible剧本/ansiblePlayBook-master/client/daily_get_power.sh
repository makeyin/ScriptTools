#!/bin/bash
hostfile=$1
cd /home/ansible/ansiblePlayBook/client
ansible-playbook getPowerPB.yml -i ${hostfile} -e "@baseClientConf.yml"  -f 30
