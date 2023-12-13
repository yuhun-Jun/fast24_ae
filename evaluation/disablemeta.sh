#!/bin/bash

#disable meta write
echo 50 > /proc/sys/vm/dirty_background_ratio
echo 50 > /proc/sys/vm/dirty_ratio
echo 0 > /proc/sys/vm/dirty_writeback_centisecs
echo 60000 > /proc/sys/vm/dirty_expire_centisecs
