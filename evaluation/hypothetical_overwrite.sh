#!/bin/bash -x
source commonvariables.sh

SRC_PATH="./hypothetical/overwrite_maker.cpp"
EXE_PATH="overwrite_maker"

OPT_DIRECT=0
OPT_DEFAULT=0

./disablemeta.sh

KB=1024
MB=`expr 1024 "*" $KB`
STRIPE_SIZE=`expr 256 "*" $KB`
APPEND_SIZE=`expr 32 "*" $KB`
WRITE_COUNT=256
FILE_SIZE=`expr 8 "*" $MB`
DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
READ_ENABLE=1

RAND_DUMMY=0


echo "filesystem test"
echo $APPEND_SIZE $STRIPE_SIZE $WRITE_COUNT


echo "Overwrtie Worst Test"
for i in {1..1}
do
    ./nvmevstart_off.sh
    sleep 1
    
    lsblk

    source setdevice.sh

    sleep 1
    DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T0
    CREAT_READ=1
    g++ -D RAND_DUMMY=$RAND_DUMMY -D CREAT_READ=$CREAT_READ -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN ./"$EXE_PATH" >> "$RESULT_FOLDER"overwrite_worst_off.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    source resetdevice.sh
done

echo "Random Overwrite Test"
RAND_DUMMY=1
for i in {1..1}
do
    ./nvmevstart_off.sh
    sleep 1
    
    lsblk

    source setdevice.sh

    sleep 1
    DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T0
    CREAT_READ=0
    g++ -D RAND_DUMMY=$RAND_DUMMY -D CREAT_READ=$CREAT_READ -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN ./"$EXE_PATH" >> "$RESULT_FOLDER"overwrite_random_off.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    source resetdevice.sh

done

echo "Random Overwrite Test"
RAND_DUMMY=1
for i in {1..1}
do
    ./nvmevstart_on.sh
    sleep 1
    
    lsblk

    source setdevice.sh

    sleep 1
    DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T0
    CREAT_READ=0
    g++ -D RAND_DUMMY=$RAND_DUMMY -D CREAT_READ=$CREAT_READ -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN ./"$EXE_PATH" >> "$RESULT_FOLDER"overwrite_random_on.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    source resetdevice.sh

done

echo "Overwrite Worst Test"
RAND_DUMMY=0
for i in {1..1}
do
    ./nvmevstart_on.sh
    sleep 1
    
    lsblk

    source setdevice.sh

    sleep 1
    DUMMYAPPEND_SIZE=`expr $STRIPE_SIZE "-" $APPEND_SIZE`
    TARGET_FILENAME=T0
    CREAT_READ=0
    g++ -D RAND_DUMMY=$RAND_DUMMY -D CREAT_READ=$CREAT_READ -D OPT_DIRECT=$OPT_DIRECT -D TARGET_FILENAME=\"$TARGET_FILENAME\" -D TARGET_FOLDER=\"$TARGET_FOLDER\" -D WRITE_COUNT=$WRITE_COUNT -D FILE_SIZE=$FILE_SIZE -D APPEND_SIZE=$APPEND_SIZE -D DUMMYAPPEND_SIZE=$DUMMYAPPEND_SIZE -D READ_ENABLE=$READ_ENABLE -o $EXE_PATH $SRC_PATH

    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN ./"$EXE_PATH" >> "$RESULT_FOLDER"overwrite_worst_on.txt

    sleep 1
    filefrag -e $TARGET_FOLDER$TARGET_FILENAME.data

    source resetdevice.sh

done

./enablemeta.sh
