#!/bin/bash -x

DATA_NAME="sdx" #The values should be set according to the each system
DATA_DEV="/dev/"$DATA_NAME""

RESULT_FOLDER=./interfaceresult/

#trim
source trim_SATA.sh

#write 2 GB
fio --ioengine=libaio --name="bstest" --rw=write --bs=512K --filename=$DATA_DEV --iodepth=1 --offset=0 --size=2GB --direct=1 --io_size=2GB

mkdir $RESULT_FOLDER

RANGE="8192 4096 2048 1024 512 256 128 64 32 16 8 4"

echo "QD 1"
QD=1

for SIZE in $RANGE
do
    echo $SIZE
    fio --loops=1 --ioengine=libaio --name="bstest" --rw=randread --bs="$SIZE"Kb --filename=$DATA_DEV --iodepth=$QD --offset=0 --size=1GB --direct=1 --io_size=8mb --output="$RESULT_FOLDER""$DATA_NAME"_"$QD"_"$SIZE".log --ramp_time=0ms --output-format=json
done

echo "QD 32"
QD=32
for SIZE in $RANGE
do
    echo $SIZE
    fio --loops=1 --ioengine=libaio --name="bstest" --rw=randread --bs="$SIZE"Kb --filename=$DATA_DEV --iodepth=$QD --offset=0 --size=1GB --direct=1 --io_size=8mb --output="$RESULT_FOLDER""$DATA_NAME"_"$QD"_"$SIZE".log --ramp_time=0ms --output-format=json
done