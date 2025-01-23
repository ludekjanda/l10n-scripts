#!/bin/bash
i=1

# start a while loop that reads the file line-by-line
while read line; do

    #increment the counter by 1 for each line read
    i=$(($i+1)) 
    # write to file
    echo "$line" > ${i}.json

done < metaobjects.txt
# passing the file as input using < (input redirection)
