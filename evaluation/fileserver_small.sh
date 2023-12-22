#!/bin/bash -x

source commonvariables.sh

#To fix filebench running problem
echo 0 > /proc/sys/kernel/randomize_va_space

./disablemeta.sh

##################################################################
echo "fileserver approach off"
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
sleep 5

./nvmevstart_off.sh

sleep 1

lsblk

source setdevice.sh

sleep 1

filebench -f filebench/fileserver_append_small.f

# copy for contiguous
rsync -av $TARGET_FOLDER/bigfileset ./

sleep 10

for reads in {1..1}
do
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
    sleep 5
    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN filebench -f filebench/fileserver_read.f >> ./$RESULT_FOLDER/fileserver_small_off.txt
done

source resetdevice.sh
##################################################################


##################################################################
echo "fileserver approach on"
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
sleep 5

./nvmevstart_on.sh

sleep 1

lsblk

source setdevice.sh

sleep 1

filebench -f filebench/fileserver_append_small.f

sleep 10

for reads in {1..1}
do
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
    sleep 5
    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN filebench -f filebench/fileserver_read.f >> ./$RESULT_FOLDER/fileserver_small_on.txt
done

source resetdevice.sh
##################################################################

##################################################################
echo "fileserver contiguous"
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
sleep 5

./nvmevstart_off.sh

sleep 1

lsblk

source setdevice.sh

sleep 1

# copy for contiguous
rsync -av ./bigfileset $TARGET_FOLDER

sleep 10

for reads in {1..1}
do
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 
    sleep 5
    numactl --cpubind=$NUMADOMAIN --membind=$NUMADOMAIN filebench -f filebench/fileserver_read.f >> ./$RESULT_FOLDER/fileserver_small_contiguous.txt
done

source resetdevice.sh
##################################################################

rm -rf bigfileset/

./enablemeta.sh