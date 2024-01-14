#!/bin/bash -x

LOOP_DEV="loop5" #The values should be set according to the each system
JOURNAL_NAME="sdb" #The values should be set according to the each system
NUMADOMAIN=2 #The values should be set according to the each system

JOURNAL_PAT_NAME=""$JOURNAL_NAME"1"
JOURNAL_DEV="/dev/"$JOURNAL_NAME""
JOURNAL_PAT="/dev/"$JOURNAL_PAT_NAME""

TARGET_FOLDER=./device/
RESULT_FOLDER=./result/

RAM_FOLDER=./ramdisk
SRC_PATH="./hypothetical/append_maker.cpp"
EXE_PATH="append_maker"

mkdir $RAM_FOLDER

KB=1024
APPEND_SIZE=`expr 32 "*" $KB`
FILE_SIZE=`expr 8192 "*" $KB`
WRITE_COUNT=`expr $FILE_SIZE "/" $APPEND_SIZE`
DUMMYAPPEND_SIZE=`expr $FILE_SIZE "-" $APPEND_SIZE`
READ_ENABLE=0

NR_SG=1
NR_DF=128
SFS="8192K"

OPT_DIRECT=0
OPT_DEFAULT=0

mount -t ramfs -o mpol=bind:0 ramfs $RAM_FOLDER
dd if=/dev/zero of=$RAM_FOLDER/ext4_1.image bs=4K count=6291456
printf "n\np\n1\n\n+2G\nw\n" | sudo fdisk $JOURNAL_DEV


mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_PAT 
mkfs.ext4 -F -J device=$JOURNAL_PAT -b 4096 -m 0 $RAM_FOLDER/ext4_1.image

mount -o loop -o nodelalloc $RAM_FOLDER/ext4_1.image $TARGET_FOLDER

lsblk #check the loop number

echo 0 > /sys/fs/ext4/$LOOP_DEV/reserved_clusters
echo 4200000000 > /sys/fs/ext4/$LOOP_DEV/mb_stream_req

D=1
while [ "$D" -le 256 ]; do

    APPEND_SIZE=`expr $FILE_SIZE "/" $D`
    WRITE_COUNT=`expr $FILE_SIZE "/" $APPEND_SIZE`
    DUMMYAPPEND_SIZE=`expr $FILE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T$D

    g++ -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -D RAND_DUMMY=0 -o $EXE_PATH $SRC_PATH

    echo $APPEND_SIZE $DUMMYAPPEND_SIZE $WRITE_COUNT

    ./"$EXE_PATH" 

    sleep 1

    rm -rf $TARGET_FOLDER/D*

    filefrag $TARGET_FOLDER$TARGET_FILENAME.data

    sleep 1

    D=$(expr $D \* 2)
done


D=1
while [ "$D" -le 256 ]; do
    echo DOF$D start | tee -a "$RESULT_FOLDER"vd_ramd_QD128.txt "$RESULT_FOLDER"vd_ramd_QD1.txt

    echo $NR_DF > /sys/block/$LOOP_DEV/queue/nr_requests
    cat /sys/block/$LOOP_DEV/queue/nr_requests
    for i in {1..1}
    do
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN dd if="${TARGET_FOLDER}T$D.data" of=/dev/null bs=$SFS iflag=direct 2>> "$RESULT_FOLDER"vd_ramd_QD128.txt
    done

    echo $NR_SG > /sys/block/$LOOP_DEV/queue/nr_requests
    cat /sys/block/$LOOP_DEV/queue/nr_requests
    for i in {1..1}
    do
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN dd if="${TARGET_FOLDER}T$D.data" of=/dev/null bs=$SFS iflag=direct 2>> "$RESULT_FOLDER"vd_ramd_QD1.txt
    done

    D=$(expr $D \* 2)
done


sleep 1
rm -rf $TARGET_FOLDER/*.data

sleep 1
umount $TARGET_FOLDER

sleep 1
rm -rf $RAM_FOLDER/*.image

sleep 1
umount $RAM_FOLDER

sleep 1
printf "d\nw\n" | sudo fdisk $JOURNAL_DEV