#!/bin/bash

hc0=$(tail -n 1 result/overwrite_worst_off.txt | grep -o 'read 1 : [0-9.]\+' | awk '{print 8 / $NF}')

aw0=$(tail -n 1 result/append_worst_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
aw1=$(tail -n 1 result/append_worst_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
ar0=$(tail -n 1 result/append_random_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
ar1=$(tail -n 1 result/append_random_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

ow0=$(tail -n 1 result/overwrite_worst_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
ow1=$(tail -n 1 result/overwrite_worst_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
or0=$(tail -n 1 result/overwrite_random_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
or1=$(tail -n 1 result/overwrite_random_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

sc0=$(tail -n 1 result/sqlite_contiguous.txt | grep -o 'time: [0-9.]\+' | awk '{print 156.25 / $NF}')
sa0=$(tail -n 1 result/sqlite_append_off.txt | grep -o 'time: [0-9.]\+' | awk '{print 156.25 / $NF}')
sa1=$(tail -n 1 result/sqlite_append_on.txt | grep -o 'time: [0-9.]\+' | awk '{print 156.25 / $NF}')

fc0=$(tail -n 2 result/fileserver_contiguous.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')
fa0=$(tail -n 2 result/fileserver_off.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')
fa1=$(tail -n 2 result/fileserver_on.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')

fsc0=$(tail -n 2 result/fileserver_small_contiguous.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')
fsa0=$(tail -n 2 result/fileserver_small_off.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')
fsa1=$(tail -n 2 result/fileserver_small_on.txt | grep -o 'rd/wr [0-9.]\+' | awk '{print $NF}')

# 결과 출력
echo " ==== Hypothetical Workload ==== "
echo " "
echo "Contiguous file: $hc0 MB/s"
echo " "
echo "Append Worst without Approach: $aw0 MB/s"
echo "Append Worst with Approach: $aw1 MB/s"
echo "Append Random without Approach: $ar0 MB/s"
echo "Append Random with Approach: $ar1 MB/s"
echo " "
echo "Overwrite Worst without Approach: $ow0 MB/s"
echo "Overwrite Worst with Approach: $ow1 MB/s"
echo "Overwrite Random without Approach: $or0 MB/s"
echo "Overwrite Random with Approach: $or1 MB/s"
echo " "
echo " ==== sqlite Workload ==== "
echo " "
echo "sqlite contiguous : $sc0 MB/s"
echo "sqlite Append without Approach: $sa0 MB/s"
echo "sqlite Append with Approach: $sa1 MB/s"
echo " "
echo " ==== fileserver Workload ==== "
echo " "
echo "fileserver contiguous : $fc0 MB/s"
echo "fileserver Append without Approach: $fa0 MB/s"
echo "fileserver Append with Approach: $fa1 MB/s"
echo " "
echo " ==== fileserver-small Workload ==== "
echo " "
echo "fileserver-small contiguous : $fsc0 MB/s"
echo "fileserver-small Append without Approach: $fsa0 MB/s"
echo "fileserver-small Append with Approach: $fsa1 MB/s"
echo " "
