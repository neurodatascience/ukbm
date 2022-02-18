#!/bin/bash

SUBJECT_LIST=$1

for i in `cat $SUBJECT_LIST`; do 
    cp -r /neurohub/ukbb/imaging/sub-${i} /output/; 
done

cp /neurohub/ukbb/imaging/{participants.tsv,dataset_description.json} /output/
