count=1

for SUBSPACE_WALLET in `cat ~/subwallet.txt`
do 
HDDHome=/data2/farmer${count}
SDDHome=/data/farmer${count}
mkdir -p  $HDDHome && mkdir -p $SDDHome
cp ~/farmer-oct-06 $HDDHome/

cat > $HDDHome/startfarmer.sh << EOF

nohup ./farmer-oct-06 --farm=hdd=$HDDHome,ssd=$SDDHome,size=100G \
farm --disk-concurrency 1 --reward-address ${SUBSPACE_WALLET} \
> /root/log/farmer${count}.log2 2>&1 &
EOF
sh $HDDHome/startfarmer.sh
count=$(($count+1))
done