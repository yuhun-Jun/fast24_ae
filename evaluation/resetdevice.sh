sleep 1
umount $TARGET_FOLDER

sleep 1
printf "d\nw\n" | sudo fdisk $DATA_DEV

sleep 1
printf "d\nw\n" | sudo fdisk $JOURNAL_DEV

rmmod nvmev

sleep 5

lsblk