#!/bin/bash
hosts=(
58.215.43.83
)
for host in ${hosts[@]}
do
rsync -avzuP --delete /tmp/ChainData_Backup/lotus devnet@$host:/tmp/ChainData_Backup/lotus
done