#write 2 GB
fio --ioengine=libaio --name="bstest" --rw=write --bs=512K --filename=$DATA_DEV --iodepth=1 --offset=0 --size=2GB --direct=1 --io_size=2GB

sleep 2

#aglined read 1GB
##bg wakeup
fio --ioengine=libaio --name="wakeup" --rw=randread --bs=4K --filename=$DATA_DEV --direct=1 --iodepth=1 --offset=0 --size=4K --norandommap --time_based --runtime=24h --thinktime=0.5s --thinktime_blocks=1 &
bg_pid=$!

sleep 2

mkdir alignresult

bsstart=4
align=$bsstart 

align=$bsstart
while [ "$align" -le 1024 ]; do
	echo bs:$bsstart align:$align
	fio --ioengine=libaio --name="align${align}" --rw=randread --bs="${bsstart}"K --size=1GB --filename=$DATA_DEV --direct=1 --iodepth=4 --ba="${align}"K --offset=0 --norandommap --output-format=json --output=./alignresult/"${DATA_NAME}_${align}".json --group_reporting --numjobs=8 --time_based --runtime=10
	align=$(expr $align \+ 4)
done

sleep 2

#kill bg
kill $bg_pid

find alignresult -type f -exec stat --format '%Y %n' {} \; | sort -n | cut -d' ' -f2- | xargs -I{} grep -m 1 -H "bw" {} > result/alignment_"$RESULT_NAME".txt

rm -rf alignresult/*.json
