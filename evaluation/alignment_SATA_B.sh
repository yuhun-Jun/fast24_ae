#!/bin/bash -x

source SATA_B.sh

DATA_DEV="/dev/"$DATA_NAME""

#trim
source trim_SATA.sh

sleep 2
source alignment_SATA.sh
