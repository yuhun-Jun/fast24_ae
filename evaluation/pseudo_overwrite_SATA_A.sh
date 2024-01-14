#!/bin/bash -x
source SATA_A.sh

#additional drive for extjournal
JOURNAL_NAME="sdb"

type="SATA"

source pseudo_overwrite_SATA.sh
