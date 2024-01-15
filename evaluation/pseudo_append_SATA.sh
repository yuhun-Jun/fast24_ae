DATA_PAT_NAME=""$DATA_NAME"1"
DATA_DEV="/dev/"$DATA_NAME""
DATA_PAT="/dev/"$DATA_PAT_NAME""

JOURNAL_PAT_NAME=""$JOURNAL_NAME"1"
JOURNAL_DEV="/dev/"$JOURNAL_NAME""
JOURNAL_PAT="/dev/"$JOURNAL_PAT_NAME""

TARGET_FOLDER=./device/
RESULT_FOLDER=./result/

SRC_PATH="hypothetical/append_maker.cpp"
EXE_PATH="append_maker"

OPT_DIRECT=0
OPT_DEFAULT=0

./disablemeta.sh

WRITE_COUNT=256
FILE_SIZE=`expr 8 "*" $MB`
DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
READ_ENABLE=1

echo "filesystem test"
echo $APPEND_SIZE $STRIPE_SIZE $WRITE_COUNT


echo "Fragmentation test"
for i in {1..1}
do
    source trim_SATA.sh

    printf "n\np\n1\n\n+2G\nw\n" | sudo fdisk $DATA_DEV
    printf "n\np\n1\n\n+1G\nw\n" | sudo fdisk $JOURNAL_DEV

    mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_PAT 
    mkfs.ext4 -F -J device=$JOURNAL_PAT -m 0 -b 4096 $DATA_PAT

    mount -o nodelalloc $DATA_PAT $TARGET_FOLDER
    echo 0 > /sys/fs/ext4/$DATA_PAT_NAME/reserved_clusters
    echo 4200000000 > /sys/fs/ext4/$DATA_PAT_NAME/mb_stream_req
    
    sleep 1
    DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T0
    g++ -D RAND_DUMMY=0 -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    ./"$EXE_PATH" >> "$RESULT_FOLDER"pseudo_append_"$RESULT_NAME"_off.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    umount $TARGET_FOLDER
    printf "d\nw\n" | sudo fdisk $DATA_DEV
    printf "d\nw\n" | sudo fdisk $JOURNAL_DEV
done


echo "Approach test"
for i in {1..1}
do
    source trim_SATA.sh

    printf "n\np\n1\n\n+2G\nw\n" | sudo fdisk $DATA_DEV
    printf "n\np\n1\n\n+1G\nw\n" | sudo fdisk $JOURNAL_DEV

    mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_PAT 
    mkfs.ext4 -F -J device=$JOURNAL_PAT -m 0 -b 4096 $DATA_PAT

    mount -o nodelalloc $DATA_PAT $TARGET_FOLDER
    echo 0 > /sys/fs/ext4/$DATA_PAT_NAME/reserved_clusters
    echo 4200000000 > /sys/fs/ext4/$DATA_PAT_NAME/mb_stream_req

    sleep 1
    DUMMYAPPEND_SIZE=$STRIPE_SIZE
    TARGET_FILENAME=T0

    g++ -D RAND_DUMMY=0 -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    ./"$EXE_PATH" >> "$RESULT_FOLDER"pseudo_append_"$RESULT_NAME"_on.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    umount $TARGET_FOLDER
    printf "d\nw\n" | sudo fdisk $DATA_DEV
    printf "d\nw\n" | sudo fdisk $JOURNAL_DEV
done

./enablemeta.sh
