# fmriprep processing 

## Notes
- Goal: Process 40k UKB subjects with fmriprep pipeline
- fmriprep version: 20.2.0
- Currently processing subset of ~3k subjects which have ses-2 and ses-3 timepoints
- Currently processing only anatomical stream

## Known issues
- BIDS sql indexing: fmriprep gets stuck while processing even a single subject when squashFS is used as an overlay. Current guess is that it tries to index all ~40k subjects from the participants.tsv which takes for ever.
  - Workaround: copy UKB subsets in scratch and mount that on singularity
- fmriprep 20.2.7 crashes with this [error(https://neurostars.org/t/error-with-select-tpl-workflow-step-in-fmriprep-20-2-6/20647)

## Organization
- Metadata: contains list of subjects for various tests and runs. 
  - ukbb_long_subject_list.txt: All subjects with two timepoints
  - ukbb_subject_ids_run1.txt: First processed subset
  - ukbb_subject_ids_run2.txt: Second processed subset
  - and so on... 

- Scripts: contains scripts to prepare data and run the pipeline
  - unsquash_data.sh and copy_ukb_data.sh: scripts to copy data from squashFS into local scratch
    e.g. ./unsquash_data.sh neurohub_ukbb_t1_ses2_0_bids.squashfs /scratch/nikhil/ukbb_processing/fmriprep/test_BIDS_DIR ukbb_long_subject_list_100.txt
  - fmriprep_anat_sub_regular.sh: script to run fmriprep in a regular setup with BIDS dataset in local FS
    e.g. ./fmriprep_anat_sub_regular.sh /home/nikhil/scratch/ukbb_processing/fmriprep/test_WD/ 1000011
  - fmriprep_anat_sub_squashfs.sh: script to run fmriprep with squashFS setup with BIDS dataset in local FS (*DOES NOT WORK WITH LARGE DATASETS*) 
  - fmriprep_anat_slurm.sh: script to submit fmriprep_anat_sub_regular.sh to slurm. This uses a list of subjects from metadata (e.g. ukbb_subject_ids_run1.txt)
    e.g. sbatch fmriprep_anat_slurm.sh /home/nikhil/scratch/ukbb_processing/fmriprep/UKB_WD
