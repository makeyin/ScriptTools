#!/bin/bash
#Usage: */10 * * * *  cd /home/devnet; ./netconnect.sh >> netconnect.log

echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to net connect other peers ============ "
peers="
/dns4/bootstrap-1.mainnet.filops.net/tcp/1347/p2p/12D3KooWCwevHg1yLCvktf2nvLu7L9894mcrJR4MsBCcm4syShVc
/dns4/bootstrap-2.mainnet.filops.net/tcp/1347/p2p/12D3KooWEWVwHGn2yR36gKLozmb4YjDJGerotAPGxmdWZx2nxMC4
/ip4/203.107.45.86/tcp/10242/p2p/12D3KooWRfaK93ndFaMNNYGPGXRoLv42LHreviEvePWYXYYXc3RZ
/ip4/61.147.117.9/tcp/33608/p2p/12D3KooW9wgC4mcDzHp8RZJcxKnNNWWmMH4N3KhenGvVvyK1szB2
/ip4/121.201.72.81/tcp/14567/p2p/12D3KooWE9SzGnHcweWu3UQaStBR1vmzjXqaN1YCTcSZ9DZ2oRAF
/ip4/118.31.168.29/tcp/44853/p2p/12D3KooWQGdc98fmHhahTjGGdkCwq6QXNYbDBpDQ9E6GGk7Jdgd4
"
for i in $peers
do
    ~/bin/lotus net connect  $i
done