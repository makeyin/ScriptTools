#!/usr/bin/env bash

set -x

NUM_SECTORS=2
SECTOR_SIZE=1024
kill `ps -u $USER -f | grep "lotus" | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

sdt0111="/home/devnet/sdt0111"
sdt0222="/home/devnet/sdt0222"

staging="/home/devnet/staging"
rm -rf ${sdt0111} ${sdt0222} ${staging}
mkdir -p ${sdt0111} ${sdt0222} ${staging}
#make pri

~/bin/lotus-seed --sectorbuilder-dir="${sdt0111}" pre-seal --miner-addr=t0111 --sector-offset=0 --sector-size=${SECTOR_SIZE} --num-sectors=${NUM_SECTORS} &
~/bin/lotus-seed --sectorbuilder-dir="${sdt0222}" pre-seal --miner-addr=t0222 --sector-offset=0 --sector-size=${SECTOR_SIZE} --num-sectors=${NUM_SECTORS} &

sleep 10

~/bin/lotus-seed aggregate-manifests "${sdt0111}/pre-seal-t0111.json" "${sdt0222}/pre-seal-t0222.json" > "${staging}/genesis.json"

lotus_path="/home/devnet/lotus_path"

rm -rf ${lotus_path}
mkdir -p ${lotus_path}

~/bin/lotus --repo="${lotus_path}" daemon --lotus-make-random-genesis="${staging}/devnet.car" --genesis-presealed-sectors="${staging}/genesis.json" --bootstrap=false &
lpid=$!

sleep 20

kill "$lpid"

wait

cp "${staging}/devnet.car" ~/bin/devnet.car

#make pri

ldt0111="/home/devnet/.lotus"
ldt0222="/home/devnet/ldt0222"
rm -rf ${ldt0111} ${ldt0222}
mkdir -p ${ldt0111} ${ldt0222}

#sdlist=( "$sdt0111" "$sdt0222" )
sdlist=( "$sdt0111" )
ldlist=( "$ldt0111" )
#ldlist=( "$ldt0111" "$ldt0222" )

for (( i=0; i<${#sdlist[@]}; i++ )); do
  preseal=${sdlist[$i]}
  fullpath=$(find ${preseal} -type f -iname 'pre-seal-*.json')
  filefull=$(basename ${fullpath})
  filename=${filefull%%.*}
  mineraddr=$(echo $filename | sed 's/pre-seal-//g')

  wallet_raw=$(jq -rc ".${mineraddr}.Key" < ${preseal}/${filefull})
  wallet_b16=$(~/bin/lotus-shed base16 "${wallet_raw}")
  wallet_adr=$(~/bin/lotus-shed keyinfo --format="{{.Address}}" "${wallet_b16}")
  wallet_adr_enc=$(~/bin/lotus-shed base32 "wallet-${wallet_adr}")

  mkdir -p "${ldlist[$i]}/keystore"
  cat > "${ldlist[$i]}/keystore/${wallet_adr_enc}" <<EOF
${wallet_raw}
EOF

  chmod 0700 "${ldlist[$i]}/keystore/${wallet_adr_enc}"
done

setsid ~/bin/lotus --repo="${ldt0111}" daemon --api 30000 --genesis=/home/devnet/bin/devnet.car --bootstrap=false  > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
#setsid ~/bin/lotus --repo="${ldt0222}" daemon --api 30001 --genesis=/home/devnet/bin/devnet.car --bootstrap=false  > ~/log/baklot.`date +"%m%d%H%M"`.out 2>&1 &

sleep 20

boot=$(~/bin/lotus --repo="${ldlist[0]}" net listen)

for (( i=1; i<${#ldlist[@]}; i++ )); do
  repo=${ldlist[$i]}
  ~/bin/lotus --repo="${repo}" net connect ${boot}
done

sleep 9

mdt0111="/home/devnet/.lotusstorage"
rm -rf ${mdt0111}
mkdir -p ${mdt0111}

export LOTUS_PATH="${ldt0111}"
export LOTUS_STORAGE_PATH="${mdt0111}"

walletDefault=`~/bin/lotus wallet list`
~/bin/lotus wallet set-default ${walletDefault}
~/bin/lotus-storage-miner init --genesis-miner --actor=t0111 --pre-sealed-sectors="${sdt0111}" --nosync=true --sector-size="${SECTOR_SIZE}"
setsid ~/bin/lotus-storage-miner run --api=4008 --nosync > ~/log/storage-miner.`date +"%m%d%H%M"`.out 2>&1 &

sleep 5
kill `ps -u $USER -f | grep "python" | grep 8989 | grep -v grep | awk '{print $2}'` 2> /dev/null
cd ~/bin; nohup python3 -m http.server 8989 &
kill `ps -u $USER -f | grep "fountain" | grep -v grep | awk '{print $2}'` 2> /dev/null
setsid ~/bin/fountain --repo=~/.lotus run --from=${walletDefault} --front=0.0.0.0:9292 > ~/log/foutain.`date +"%m%d%H%M"`.out 2>&1 &