#!/bin/bash

# Author: nikhil153
# Last update: 18 Feb 2022
# Script to extract subset of data from squashFS into regular FS

if [ "$#" -ne 3 ]; then
  echo "Please provide squashFS, output_dir and list of subjects in a text file"
  exit 1
fi

SQUASHFS=$1 #neurohub_ukbb_t1_ses2_0_bids.squashfs
OUTPUT_DIR=$2
SUBJECT_LIST=$3

CON_IMG=/project/rpp-aevans-ab/neurohub/ukbb/example_singularity.sif
UKBB_SQUASHFS_DIR=/project/6008063/neurohub/ukbb/imaging

# SquashFS list
UKBB_SQUASHFS="
 ${SQUASHFS}
 neurohub_ukbb_participants.squashfs
 neurohub_ukbb_t1_ses2_0_jsonpatch.squashfs
 "

# Append all the squashFS files (we need participants and patches to maintain BIDS validation)
UKBB_OVERLAYS=$(echo "" $UKBB_SQUASHFS | sed -e "s# # --overlay $UKBB_SQUASHFS_DIR/#g")
echo "overlays:"
echo $UKBB_OVERLAYS

CMD=${for i in cat $SUBJECT_LIST; do cp /neurohub/ukbb/imaging/${i} /output/; done \
    cp participants.tsv dataset_description.json /output/}

singularity run --overlay UKBB_OVERLAYS -B $OUTPUT_DIR:/output CON_IMG $CMD
