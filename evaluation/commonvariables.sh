####################
#Modify the following values to suit your system
DATA_NAME="nvme4n1"
JOURNAL_NAME="sdb"
NUMADOMAIN=2
####################

DATA_PAT_NAME=""$DATA_NAME"p1"
DATA_DEV="/dev/"$DATA_NAME""
DATA_PAT="/dev/"$DATA_PAT_NAME""

JOURNAL_PAT_NAME=""$JOURNAL_NAME"1"
JOURNAL_DEV="/dev/"$JOURNAL_NAME""
JOURNAL_PAT="/dev/"$JOURNAL_PAT_NAME""

TARGET_FOLDER=./device/
RESULT_FOLDER=./result/