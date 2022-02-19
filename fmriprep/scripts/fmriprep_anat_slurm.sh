#!/bin/bash

#SBATCH -J ukbb_test_run
#SBATCH --time=23:00:00
#SBATCH --account=rrg-jbpoline
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
# Outputs ----------------------------------
#SBATCH -o ./slurm_logs_run_long/%x-%A-%a_%j.out
#SBATCH -e ./slurm_logs_run_long/%x-%A-%a_%j.err
#SBATCH --mail-user=nikhil.bhagwat@mcgill.ca
#SBATCH --mail-type=ALL
# ------------------------------------------

#SBATCH --array=1-1000

WD_DIR=$1

echo "Starting task $SLURM_ARRAY_TASK_ID"
SUB_ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ../metadata/ukbb_subject_ids_run_long_1.txt)
echo "Subject ID: ${SUB_ID}"

module load singularity/3.8
./fmriprep_anat_sub_regular_20.2.7.sh ${WD_DIR} ${SUB_ID}
