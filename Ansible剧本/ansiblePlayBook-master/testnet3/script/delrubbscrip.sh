#/bin/bash

tank1_size=`df -h | awk '{if($6~"tank1") print $5}' | awk -F "%" '{print $1}'`
tank2_size=`df -h | awk '{if($6~"tank2") print $5}' | awk -F "%" '{print $1}'`
AddPiece=`cat .lotusslave/storage.json| grep AddPiece| awk -F ":" '{print $2}' |awk -F "," '{print $1}'`
vl_info = `~/bin/view_lotus.sh info`
if [ vl_info -ne 0 ]; then
    echo "slave The process is not running"
    exit 1
    
elif [ ${tank1_size} > 95 -o ${tank2_size} > 95]; then
    ~/delRubbFile.sh  delete
    if [ ${AddPiece} -ne 0 ]; then
       sed -i 's/"AddPieceLimit".*/"AddPieceLimit": 0,/g' ~/.lotusslave/storage.json
    fi
else
    echo "succeed"

