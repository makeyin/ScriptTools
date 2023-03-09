#!/bin/bash
  
#maxSize 4T, should be 2^22
maxM=9
maxG=5
maxT=0
powerFilePath=/data/powerData
################
mkdir -p $powerFilePath

a=1
dd if=/dev/zero of=$powerFilePath/power_${a}MB bs=1M count=$a

for ((i=1; i<= $maxM; i++))
  do
    let a=a*2
    echo $a
    dd if=/dev/zero of=$powerFilePath/power_${a}MB bs=1M count=$a  #creat MB file
done


a=1
dd if=/dev/zero of=$powerFilePath/power_${a}GB bs=1G count=$a

for ((i=1; i<= $maxG; i++))
  do
    let a=a*2
    echo $a
    dd if=/dev/zero of=$powerFilePath/power_${a}GB bs=1G count=$a  #creat MB file
done

a=1024
for ((i=1; i<= $maxT; i++))
  do
    let a=a*2
    echo $a
    dd if=/dev/zero of=$powerFilePath/power_${a}TB bs=1G count=$a  #creat MB file
done
