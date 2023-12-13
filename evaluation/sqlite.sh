#!/bin/bash -x

source commonvariables.sh

SRC_PATH="sqlite"

gcc -D TARGET_FOLDER=\"$TARGET_FOLDER\" -o ./sqlite_append ./$SRC_PATH/sqlite_append.c -lsqlite3
gcc -D TARGET_FOLDER=\"$TARGET_FOLDER\" -o ./sqlite_ideal ./$SRC_PATH/sqlite_contiguous.c -lsqlite3

./disablemeta.sh

# contiguous
./nvmevstart_off.sh
sleep 1

lsblk

source setdevice.sh

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

numactl --cpubind=2 --membind=2 ./sqlite_ideal >> ./$RESULT_FOLDER/sqlite_contiguous.txt

source resetdevice.sh

# fragment approach off
./nvmevstart_off.sh
sleep 1

lsblk

source setdevice.sh

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

numactl --cpubind=2 --membind=2 ./sqlite_append >> ./$RESULT_FOLDER/sqlite_append_off.txt

source resetdevice.sh

# fragment approach on
./nvmevstart_on.sh
sleep 1

lsblk

source setdevice.sh

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

numactl --cpubind=2 --membind=2 ./sqlite_append >> ./$RESULT_FOLDER/sqlite_append_on.txt

source resetdevice.sh


./enablemeta.sh
