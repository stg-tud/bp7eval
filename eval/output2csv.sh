#!/bin/sh

echo program,test,runs,crc,bundles/second > $1/complete.csv

for i in $1/*.out; do
    VARIANT=$(basename $i)
    cat $i | grep "bundles/second" |  tail -n +10 | awk '$1=$1' |\
        sed -e "s/://g" | \
        sed -e "s/^/$VARIANT /" | \
        sed -e "s/with/$VARIANT/" | \
        cut -d " " -f 1,2,3,6,7 | sed -e "s/ /,/g" | tee $1/$VARIANT.csv
    
    cat $1/$VARIANT.csv >> $1/complete.csv
done

#cat $1/*.csv >> $1/complete.csv