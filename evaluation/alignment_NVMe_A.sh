#!/bin/bash -x

source NVMe_A.sh

DATA_DEV="/dev/"$DATA_NAME""

#trim
source trim_NVMe.sh

sleep 2
source alignment_NVMe.sh
