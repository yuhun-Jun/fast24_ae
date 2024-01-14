DATA_NAME="sda"
RESULT_NAME="SATA-A"

KB=1024
MB=`expr 1024 "*" $KB`
STRIPE_SIZE=`expr 32 "*" $KB`
APPEND_SIZE=`expr 4 "*" $KB`
