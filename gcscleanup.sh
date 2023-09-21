#!/bin/bash

# Usage: ./gcscleanup.sh "bucketname" "7 days"

gsutil ls gs://$1 | grep " DIR " -v | while read -r line;
  do
    createDate=`echo $line|awk {'print $1" "$2'}`
    createDate=$(date -d "$createDate" "+%s")
    olderThan=$(date -d "$2 ago" "+%s")
    if [[ $createDate -le $olderThan ]];
      then
        fileName=`echo $line|awk {'print $4'}`
        if [ $fileName != "" ]
          then
            printf 'Deleting "%s"\n' $fileName
            s3cmd rm "$fileName"
        fi
    fi
  done;
