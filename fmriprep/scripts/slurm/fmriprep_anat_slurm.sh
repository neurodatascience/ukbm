#!/bin/bash

#SBATCH -J ukbb_test_run
#SBATCH --time=23:00:00
#SBATCH --account=rrg-jbpoline
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
# Outputs ----------------------------------
#SBATCH -o ./slurm_logs/ukbb_long_run1/%x-%A-%a_%j.out
#SBATCH -e ./slurm_logs/ukbb_long_run1/%x-%A-%a_%j.err
#SBATCH --mail-user=nikhil.bhagwat@mcgill.ca
#SBATCH --mail-type=ALL
# ------------------------------------------

#SBATCH --array=1-300

BIDS_DIR=$1 #"/scratch/nikhil/ukbb_processing/fmriprep/BIDS_DIR_ses-2"
SUBJECT_LIST=$2 #../metadata/ukbb_subject_ids_long_run_1.txt
WD_DIR=$3 #/scratch/nikhil/ukbb_processing/fmriprep/UKB_WD_ses-2/run1

echo "Starting task $SLURM_ARRAY_TASK_ID"
SUB_ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $SUBJECT_LIST)
echo "Subject ID: ${SUB_ID}"

module load singularity/3.8
../fmriprep_anat_sub_regular_20.2.7.sh ${BIDS_DIR} ${WD_DIR} ${SUB_ID}
