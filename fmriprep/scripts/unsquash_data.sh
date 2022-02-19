#!/bin/bash

# Author: nikhil153
# Last update: 18 Feb 2022
# Script to extract subset of data from squashFS into regular FS

if [ "$#" -ne 3 ]; then
  echo "Please provide squashFS, output_dir and list of subjects from /fmriprep/metadata dir"
  exit 1
fi

SQUASHFS=$1 #neurohub_ukbb_t1_ses2_0_bids.squashfs
OUTPUT_DIR=$2
SUBJECT_LIST=$3

CON_IMG=/project/rpp-aevans-ab/neurohub/ukbb/example_singularity.sif
UKBB_SQUASHFS_DIR=/project/6008063/neurohub/ukbb/imaging

#SquashFS list
if [ ${SQUASHFS} == "anat" ]; then
  echo "Using only anat data with all sessions"
  UKBB_SQUASHFS="
   neurohub_ukbb_t1_ses2_0_bids.squashfs
   neurohub_ukbb_t1_ses3_0_bids.squashfs
   neurohub_ukbb_participants.squashfs
   neurohub_ukbb_t1_ses2_0_jsonpatch.squashfs
   "

else
  echo "Using anat and func scans with all sessions"
  # TODO

fi

UKBB_OVERLAYS=$(echo "" $UKBB_SQUASHFS | sed -e "s# # --overlay $UKBB_SQUASHFS_DIR/#g")
echo "overlays:"
echo $UKBB_OVERLAYS

#CMD="for i in `cat $SUBJECT_LIST`; do echo $i; cp /neurohub/ukbb/imaging/${i} /output/; done"

singularity run $UKBB_OVERLAYS -B $OUTPUT_DIR:/output \
 -B /home/nikhil/scratch/ukbb_processing/ukbm/fmriprep:/fmriprep \
 $CON_IMG /fmriprep/scripts/copy_ukb_data.sh /fmriprep/metadata/$SUBJECT_LIST
