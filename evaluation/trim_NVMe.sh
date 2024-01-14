#trim
echo "trim command"
nvme format $DATA_DEV --ses=1 --pi=0 --namespace-id=1

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sleep 5

echo "trim wait read 5min"
sudo fio --ioengine=libaio --name="waittrim" --rw=randread --bs=4K --filename=$DATA_DEV --direct=1 --iodepth=1 --offset=0 --norandommap --time_based --runtime=5m --thinktime=1s --thinktime_blocks=1    

sleep 2