#trim
echo "trim command"

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sleep 5

hdparm --user-master u --security-set-pass p $DATA_DEV
hdparm --user-master u --security-erase-enhanced p $DATA_DEV


sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sleep 5
sudo fio --ioengine=libaio --name="waittrim" --rw=randread --bs=4K --filename=$DATA_DEV --direct=1 --iodepth=1 --offset=0 --norandommap --time_based --runtime=5m --thinktime=1s --thinktime_blocks=1    

sleep 2