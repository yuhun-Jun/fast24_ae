#!/bin/bash

hcA0=$(tail -n 1 result/pseudo_overwrite_SATA-A_off.txt | grep -o 'read 1 : [0-9.]\+' | awk '{print 8 / $NF}')

awA0=$(tail -n 1 result/pseudo_append_SATA-A_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
awA1=$(tail -n 1 result/pseudo_append_SATA-A_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

owA0=$(tail -n 1 result/pseudo_overwrite_SATA-A_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
owA1=$(tail -n 1 result/pseudo_overwrite_SATA-A_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

hcB0=$(tail -n 1 result/pseudo_overwrite_SATA-B_off.txt | grep -o 'read 1 : [0-9.]\+' | awk '{print 8 / $NF}')

awB0=$(tail -n 1 result/pseudo_append_SATA-B_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
awB1=$(tail -n 1 result/pseudo_append_SATA-B_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

owB0=$(tail -n 1 result/pseudo_overwrite_SATA-B_off.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')
owB1=$(tail -n 1 result/pseudo_overwrite_SATA-B_on.txt | grep -o 'read 2 : [0-9.]\+' | awk '{print 8 / $NF}')

# print
echo " ==== Hypothetical SATA Workload ==== "
echo " SATA-A "
echo "Contiguous file: $hcA0 MB/s"
echo " "
echo "Append Worst without Approach: $awA0 MB/s"
echo "Append Worst with Approach: $awA1 MB/s"
echo " "
echo "Overwrite Worst without Approach: $owA0 MB/s"
echo "Overwrite Worst with Approach: $owA1 MB/s"
echo " "
echo " SATA-B "
echo "Contiguous file: $hcB0 MB/s"
echo " "
echo "Append Worst without Approach: $awB0 MB/s"
echo "Append Worst with Approach: $awB1 MB/s"
echo " "
echo "Overwrite Worst without Approach: $owB0 MB/s"
echo "Overwrite Worst with Approach: $owB1 MB/s"
echo " "
