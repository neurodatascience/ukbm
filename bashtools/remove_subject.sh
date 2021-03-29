#!/bin/bash

helpstr="$(basename "$0") [-h] [-d DIRECTORY] [-o OUTPUT_DIR] [-a ACCOUNT] subject_list singularity_img squashfs_0 [squashfs_1 ...] - Re-squashes the input SquashFS files without the subjects listed

where:
  -h                            Show this message.
  -d DIRECTORY                  Directory to squash. (typically directory in /)
  -o OUTPUT_DIR                 Directory where to save resquashed images
  -a ACCOUNT                    Account to use for SLURM accounting.
  subject_list                  Text file with subject directories to remove.
  singularity_img               Singularity image to use to mount SquashFS files.
  squashfs                     SquashFS files to mount, check, and resquash without the subjects to be removed.
"

squash_dir="/data/"
posargs=()
# Arg parse
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "Usage: ${helpstr}"
      exit 0
      ;;
    -d|--directory)
      squash_dir="$2"
      shift 2
      ;;
    -o|--output)
      output="$2"
      shift 2
      ;;
    -a|--account)
      account="$2"
      shift 2
      ;;
    -*|--*)
      echo "Unrecognized option: ${1}"
      exit 1
      ;;
    *)
      posargs+=("$1")
      shift 1
      ;;
  esac
done

subject_list=${posargs[0]}
singularity_img=${posargs[1]}
squash_list=${posargs[@]:2}

if [ -n ${SLURM_JOB_ID} ]; then
  ST=${SLURM_TMPDIR}
  is_slurm=1
  module load singularity/3.6
else
  ST=`mktemp -d`
  is_slurm=0
fi

script_dir=`readlink -f $0`
# Mount each SquashFS image; check; create list of images to be rebuilt
squash_to_fix=()
for squash in "${squash_list[@]}"; do
  buf=`singularity exec -B ${script_dir}:/fix_scripts/ --overlay "${squash}":ro "${singularity_img}" bash /fix_scripts/check_subject.sh`
  if [ ${buf} -eq 1 ]; then
    squash_to_fix+=(${squash})
  fi
done
