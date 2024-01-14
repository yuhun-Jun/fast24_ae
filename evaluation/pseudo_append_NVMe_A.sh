#!/bin/bash -x
source NVMe_A.sh

#additional drive for extjournal
JOURNAL_NAME="sdb"

source pseudo_append_NVMe.sh
