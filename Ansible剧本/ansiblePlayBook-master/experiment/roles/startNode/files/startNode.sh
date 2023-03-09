#killall -u filecoin go-filecoin
kill -9 `cat ~/bin/PID.NODE`

mkdir -p ~/log
rm -f ~/log/filecoin*

logFile="filecoin.`date +"%m%d%H%M"`.out"

if [ -f "~/.filecoin/repo.lock" ]; then
  rm -f ~/.filecoin/repo.lock
fi

if [ -f "~/.filecoin/badger/LOCK" ]; then
  rm -f ~/.filecoin/badger/LOCK
fi

if [ -f "~/.filecoin/chain/LOCK" ]; then
  rm -f ~/.filecoin/chain/LOCK
fi

setsid ~/bin/go-filecoin daemon > ~/log/$logFile 2>&1  &
echo $! > ~/bin/PID.NODE

sleep 5

### simply check log
if [ `grep -c "no filecoin repo found in" ~/log/$logFile` -ne '0' ]; then
    echo `grep "no filecoin repo found in" ~/log/$logFile`
    exit 1
fi

if [ `grep -c "bind: address already in use" ~/log/$logFile` -ne '0' ]; then
    echo `grep "bind: address already in use" ~/log/$logFile`
    exit 1
fi

if [ `grep -c "failed to get key from keystore" ~/log/$logFile` -ne '0' ]; then
    echo `grep "failed to get key from keystore" ~/log/$logFile`
    exit 1
fi

exit 0

