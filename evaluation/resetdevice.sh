sleep 1
umount $TARGET_FOLDER

sleep 1
printf "d\nd\nw\n" | sudo fdisk $DATA_DEV
#Depending on the system, deletion might not occur in one attempt, so it is done twice

sleep 1
printf "d\nd\nw\n" | sudo fdisk $JOURNAL_DEV
#Depending on the system, deletion might not occur in one attempt, so it is done twice

rmmod nvmev

sleep 5

lsblk
