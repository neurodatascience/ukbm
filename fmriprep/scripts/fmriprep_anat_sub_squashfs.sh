#!/bin/bash

# Author: nikhil153
# Last update: 16 Feb 2022

if [ "$#" -ne 2 ]; then
  echo "Please provide path to the working_dir and subject ID (i.e. subdir inside BIDS_root)"
  exit 1
fi

WD_DIR=$1
SUB_ID=$2

BIDS_DIR="/neurohub/ukbb/imaging/"
CON_IMG="/home/nikhil/scratch/my_containers/fmriprep_20.2.7.sif"
DERIVS_DIR=${WD_DIR}/output

LOG_FILE=${WD_DIR}_fmriprep_anat.log
echo "Starting fmriprep proc with container: ${CON_IMG}"
echo ""
echo "Using working dir: ${WD_DIR} and subject ID: ${SUB_ID}"

# Create subject specific dirs
FMRIPREP_HOME=${DERIVS_DIR}/fmriprep_home_${SUB_ID}
echo "Processing: ${SUB_ID} with home dir: ${FMRIPREP_HOME}"
mkdir -p ${FMRIPREP_HOME}

LOCAL_FREESURFER_DIR="${DERIVS_DIR}/freesurfer-6.0.1"
mkdir -p ${LOCAL_FREESURFER_DIR}

# Prepare some writeable bind-mount points.
FMRIPREP_HOST_CACHE=$FMRIPREP_HOME/.cache/fmriprep
mkdir -p ${FMRIPREP_HOST_CACHE}

# CHECK IF YOU HAVE TEMPLATEFLOW
TEMPLATEFLOW_HOST_HOME="/home/nikhil/scratch/templateflow"

# Make sure FS_LICENSE is defined in the container.
mkdir -p $FMRIPREP_HOME/.freesurfer
export SINGULARITYENV_FS_LICENSE=$FMRIPREP_HOME/.freesurfer/license.txt
cp ${WD_DIR}/license.txt ${SINGULARITYENV_FS_LICENSE}

# Designate a templateflow bind-mount point
export SINGULARITYENV_TEMPLATEFLOW_HOME="/templateflow"

# SquashFS list
UKBB_SQUASHFS="
 neurohub_ukbb_t1_ses2_0_bids.squashfs
 neurohub_ukbb_participants.squashfs
 neurohub_ukbb_t1_ses2_0_jsonpatch.squashfs
 "

UKBB_SQUASHFS_DIR=/project/6008063/neurohub/ukbb/imaging
UKBB_OVERLAYS=$(echo "" $UKBB_SQUASHFS | sed -e "s# # --overlay $UKBB_SQUASHFS_DIR/#g")
echo "overlays:"
echo $UKBB_OVERLAYS

data_dir=$BIDS_DIR

echo "data dir: $data_dir"

# Singularity CMD 
SINGULARITY_CMD="singularity run \
${UKBB_OVERLAYS} \
-B ${FMRIPREP_HOME}:/home/fmriprep --home /home/fmriprep --cleanenv \
-B ${DERIVS_DIR}:/output \
-B ${TEMPLATEFLOW_HOST_HOME}:${SINGULARITYENV_TEMPLATEFLOW_HOME} \
-B ${WD_DIR}:/work \
-B ${LOCAL_FREESURFER_DIR}:/fsdir \
 ${CON_IMG}"

# Remove IsRunning files from FreeSurfer
# find ${LOCAL_FREESURFER_DIR}/sub-$SUB_ID/ -name "*IsRunning*" -type f -delete

# Compose the command line
cmd="${SINGULARITY_CMD} ${data_dir} /output participant --participant-label $SUB_ID \
-w /work --output-spaces MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5 \
--fs-subjects-dir /fsdir \
--fs-license-file /home/fmriprep/.freesurfer/license.txt \
--return-all-components --anat-only -v \
--write-graph  --notrack --resource-monitor"
#--bids-filter-file ${BIDS_FILTER} --anat-only --cifti-out 91k"

# Setup done, run the command
#echo Running task ${SLURM_ARRAY_TASK_ID}
echo Commandline: $cmd
unset PYTHONPATH
eval $cmd
exitcode=$?

# Output results to a table
echo "$SUB_ID    ${SLURM_ARRAY_TASK_ID}    $exitcode"
echo Finished tasks ${SLURM_ARRAY_TASK_ID} with exit code $exitcode
rm -rf ${FMRIPREP_HOME}
exit $exitcode

echo "Submission finished!"
