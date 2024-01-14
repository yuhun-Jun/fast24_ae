DATA_NAME="nvme1n1"
RESULT_NAME="NVMe-B"

KB=1024
MB=`expr 1024 "*" $KB`
STRIPE_SIZE=`expr 256 "*" $KB`
APPEND_SIZE=`expr 32 "*" $KB`
