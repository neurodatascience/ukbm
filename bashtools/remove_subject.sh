#!/bin/bash

helpstr="$(basename "$0") [-h] [-d DIRECTORY] [-o OUTPUT_DIR] [-a ACCOUNT] subject_list singularity_img squashfs_0 [squashfs_1 ...] - Re-squashes the input SquashFS files without the subjects listed

where:
  -h                            Show this message.
  -d DIRECTORY                  Directory to squash. (typically directory in /)
  -o OUTPUT_DIR                 Directory where to save resquashed images
  -a ACCOUNT                    Account to use for SLURM accounting.
  -j, --json DATASET_DESC.json	Replacement for dataset_description.json.
  subject_list                  Text file with subject directories to remove.
  singularity_img               Singularity image to use to mount SquashFS files.
  squashfs                      SquashFS files to mount, check, and resquash without the subjects to be removed.
"

squash_dir="/data/"
output="./"
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
    -j|--json)
      dataset_desc="${2}"
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
squash_list=(${posargs[@]:2})

# Get script location
script_dir=`readlink -f $0`
script_dir=`dirname ${script_dir}`
slr=`readlink -f ${subject_list}`
subject_list_dir=`dirname ${slr}`
# Mount each SquashFS image; check; create list of images to be rebuilt
squash_to_fix=()
for squash in "${squash_list[@]}"; do
  echo "Checking ${squash}..."
  buf=`singularity exec -B ${script_dir}:/fix_scripts/ -B ${subject_list_dir}:/.subjects/ --overlay "${squash}":ro "${singularity_img}" bash /fix_scripts/check_subject.sh /.subjects/${subject_list}`
  if [ "${buf}" -eq 1 ]; then
    squash_to_fix+=(${squash})
    echo "Needs fixing: ${squash}"
    continue
  fi
done
# subject_list singularity_img output_dir topdir squashfs_0
for squash in "${squash_to_fix[@]}"; do
  echo "Submitting ${squash} ..."
  if [ -n "${dataset_desc}" ]; then
    sbatch --account=${account} -J "resquash" ${script_dir}/resquash.sh -p -j ${dataset_desc} ${subject_list} ${singularity_img} ${output} ${squash_dir} ${squash}
  else
    sbatch --account=${account} -J "resquash" ${script_dir}/resquash.sh -p  ${subject_list} ${subject_list} ${singularity_img} ${output} ${squash_dir} ${squash}
  fi
done
