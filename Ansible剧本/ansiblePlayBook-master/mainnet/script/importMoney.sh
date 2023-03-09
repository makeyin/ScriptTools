#keyFile="wallet_key_full.txt"
keyFile=$1
echo $keyFile
walletAddress=t3wnbphpcsyddbgcxrkww52izaullfhbuwzgyhiop6r3tgiw4lbjkbr5gnjsjxw42k7btwv2ofdt2lodmbe4za
mkdir -p key_tmp_file

for line in `cat $keyFile |awk '{print $2}'`
do
  echo $line > ./key_tmp_file/$line
  ls -l key_tmp_file |awk '{print $9}' > key_tmp_file/key.txt
done

for line in `grep 7b22 key_tmp_file/key.txt`
do
   ~/bin/lotus wallet import key_tmp_file/$line
done

echo "---------- send money -------------"
for line in `cat $keyFile |awk '{print $1}'`
do
   ~/bin/lotus send --from  $line  $walletAddress 63990
done