
FILE_SIZE=`expr 8192 "*" $KB`
READ_OP=0

TARGET_FOLDER=./device/
RESULT_FOLDER=./result/
SRC_PATH="./hypothetical/append_maker.cpp"
EXE_PATH="append_maker"

NR_SG=1
NR_DF=1023
SFS="8192K"

OPT_DIRECT=0
OPT_DEFAULT=1

DRANGE="1 2 4 8 16 32 64 128 256"
for D in $DRANGE
do

    DATA_PAT_NAME=""$DATA_NAME"p1"
    DATA_DEV="/dev/"$DATA_NAME""
    DATA_PAT="/dev/"$DATA_PAT_NAME""

    JOURNAL_PAT_NAME=""$JOURNAL_NAME"1"
    JOURNAL_DEV="/dev/"$JOURNAL_NAME""
    JOURNAL_PAT="/dev/"$JOURNAL_PAT_NAME""

    ####trim, fdisk, mount
    source trim_NVMe.sh

    #disable meta write
    ./disablemeta.sh

    ###format mount
    printf "n\np\n1\n\n+35G\nw\n" | sudo fdisk $DATA_DEV
    printf "n\np\n1\n\n+2G\nw\n" | sudo fdisk $JOURNAL_DEV

    mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_PAT 
    mkfs.ext4 -F -J device=$JOURNAL_PAT -m 0 -b 4096 $DATA_PAT

    mount -o nodelalloc $DATA_PAT $TARGET_FOLDER
    echo 0 > /sys/fs/ext4/$DATA_PAT_NAME/reserved_clusters
    echo 4200000000 > /sys/fs/ext4/$DATA_PAT_NAME/mb_stream_req

    ###makefile
    APPEND_SIZE=`expr $FILE_SIZE "/" $D`
    WRITE_COUNT=`expr $FILE_SIZE "/" $APPEND_SIZE`
    DUMMYAPPEND_SIZE=`expr $FILE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T$D

    g++ -D RAND_DUMMY=0 -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_OPTION=$READ_OP -o $EXE_PATH $SRC_PATH

    echo $APPEND_SIZE $DUMMYAPPEND_SIZE $WRITE_COUNT

    ./"$EXE_PATH" 

    rm -rf $TARGET_FOLDER/D*

    filefrag $TARGET_FOLDER$TARGET_FILENAME.data

    sleep 1

    ###read test

    #bg wakeup
    fio --ioengine=libaio --name="wakeup" --rw=randread --bs=4K --filename=$DATA_DEV --direct=1 --iodepth=1 --offset=0 --size=4K --norandommap --time_based --runtime=24h --thinktime=0.5s --thinktime_blocks=1 &
    bg_pid=$!

    sleep 1
  
    echo $NR_DF > /sys/block/$DATA_NAME/queue/nr_requests
    cat /sys/block/$DATA_NAME/queue/nr_requests
    for i in {1..1}
    do
        echo DOF$D start | tee -a $RESULT_FOLDER"vd_$RESULT_NAME"_QD"$NR_DF".txt
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        dd if="${TARGET_FOLDER}T$D.data" of=/dev/null bs=$SFS iflag=direct >> $RESULT_FOLDER"vd_$RESULT_NAME"_QD"$NR_DF".txt 2>&1
    done

    echo $NR_SG > /sys/block/$DATA_NAME/queue/nr_requests
    cat /sys/block/$DATA_NAME/queue/nr_requests
    for i in {1..1}
    do
        echo DOF$D start | tee -a $RESULT_FOLDER"vd_$RESULT_NAME"_QD"$NR_SG".txt
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
        sleep 5
        dd if="${TARGET_FOLDER}T$D.data" of=/dev/null bs=$SFS iflag=direct >> $RESULT_FOLDER"vd_$RESULT_NAME"_QD"$NR_SG".txt 2>&1
    done

    echo $NR_DF > /sys/block/$DATA_NAME/queue/nr_requests

    #kill bg wakeup
    kill $bg_pid

    ###reset umount

    sleep 1

    umount $TARGET_FOLDER
    sleep 1
    printf "d\nw\n" | sudo fdisk $DATA_DEV
    printf "d\nw\n" | sudo fdisk $JOURNAL_DEV

    #enable meta write
    ./enablemeta.sh

done




