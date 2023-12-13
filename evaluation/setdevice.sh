
printf "n\np\n1\n\n+50G\nw\n" | sudo fdisk $DATA_DEV
printf "n\np\n1\n\n+1G\nw\n" | sudo fdisk $JOURNAL_DEV

mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_PAT 
mkfs.ext4 -F -J device=$JOURNAL_PAT -m 0 -b 4096 $DATA_PAT

mount -o nodelalloc $DATA_PAT $TARGET_FOLDER
echo 0 > /sys/fs/ext4/$DATA_PAT_NAME/reserved_clusters
echo 4200000000 > /sys/fs/ext4/$DATA_PAT_NAME/mb_stream_req
