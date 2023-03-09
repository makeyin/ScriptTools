
ImportKey.sh 

chmod +x ImportKey.sh

start ImportKey.sh 

sleep 5s

start changeConfig.sh

nohup $sdsHome/installSds.sh 2>&1  >> install.log &
sleep 5s

sed -i  's/127.0.0.1:8888/13.58.35.167:8888/g' $sdsHome/configs/config.toml
sed -i "/network_address/ s/127.0.0.1/103.90.155.133/g" $sdsHome/configs/config.toml
sed -i "/port/ s/18081/${Netw}/g" $sdsHome/configs/config.toml
sed -i "s|http://127.0.0.1:1317|https://rest-tropos.thestratos.org:443|g" $sdsHome/configs/config.toml
cat >> $sdsHome/configs/config.toml<<EOF
[[sp_list]]
p2p_address = 'stsds1mr668mxu0lyfysypq88sffurm5skwjvjgxu2xt'
p2p_public_key = 'stsdspub1zcjduepq4v8yu6nzem787nfnwvzrfvpc5f7thktsqjts6xp4cy4a2j4rgm7sgdy4zy'
network_address = '35.73.160.68:8888'
[[sp_list]]
p2p_address = 'stsds1ftcvm2h9rjtzlwauxmr67hd5r4hpxqucjawpz6'
p2p_public_key = 'tsdspub1zcjduepqq9rk5zwkzfnnszt5tqg524meeqd9zts0jrjtqk2ly2swm5phlc2qtrcgys'
network_address = '46.51.251.196:8888'
[[sp_list]]
p2p_address = 'stsds12uufhp4wunhy2n8y5p07xsvy9htnp6zjr40tuw'
p2p_public_key = 'stsdspub1zcjduepqkst98p2642fv8eh8297ppx7xuzu7qjz67s9hjjhxjxs834md7e0s5rm3lf'
network_address = '18.130.202.53:8888'
[[sp_list]]
p2p_address = 'stsds1wy6xupax33qksaguga60wcmxpk6uetxt3h5e3e'
p2p_public_key = 'stsdspub1zcjduepqyyfl7ljwc68jh2kuaqmy84hawfkak4fl2sjlpf8t3dd00ed2eqeqlm65ar'
network_address = '35.74.33.155:8888'
[[sp_list]]
p2p_address = 'stsds1nds6cwl67pp7w4sa5ng5c4a5af9hsjknpcymxn'
p2p_public_key = 'stsdspub1zcjduepq6mz8w7dygzrsarhh76tnpz0hkqdq44u7usvtnt2qd9qgp8hs8wssl6ye0g'
network_address = '52.13.28.64:8888'
[[sp_list]]
p2p_address = 'stsds1403qtm2t7xscav9vd3vhu0anfh9cg2dl6zx2wg'
p2p_public_key = 'stsdspub1zcjduepqzarvtl2ulqzw3t42dcxeryvlj6yf80jjchvsr3s8ljsn7c25y3hq2fv5qv'
network_address = '3.9.152.251:8888'
[[sp_list]]
p2p_address = 'stsds1hv3qmnujlrug00frk86zxr0q23rnqcaquh62j2'
p2p_public_key = 'stsdspub1zcjduepqj69eeq07yfdgu4cdlupvga897zjqjakuru0qar5na7as4kjr7jgs0k7aln'
network_address = '18.223.175.117:8888'
EOF