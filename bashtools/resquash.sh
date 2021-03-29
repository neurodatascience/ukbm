#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=8G
#SBATCH --time=0-12:00:00
#SBATCH --array=0

helpstr="$(basename "$0") [-h] subject_list singularity_img output_dir topdir squashfs_0 [squashfs_1 ...] - Re-squashes the input SquashFS files without the subjects listed

where:
  -h                            Show this message.
  subject_list                  Text file with subject directories to remove.
  singularity_img               Singularity image to use to mount SquashFS files.
  output_dir                    Path to put resquashed images
  topdir                        Path in SquashFS image to squash.
  squashfs_files                SquashFS files to mount, check, and resquash without the subjects to be removed.
"

pos_args=()
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo $helpstr
      exit 0
      ;;
    *)
      pos_args+=("$1")
      shift 1
      ;;
  esac
done

exclude_file=${pos_args[0]}
singularity_image=${pos_args[1]}
output_dir=${pos_args[2]}
topdir=${pos_args[3]}
squash_list=("${pos_args[@]:4}")
squash_file=${squash_list[${SLURM_ARRAY_TASK_ID}]}

output_name=`basename ${squash_file}`
ind=0
while [ -f ${output_dir}/${output_name} ]; do
  output_name=${output_name%%.*}_${ind}.${output_name#*.}
  ind=$((ind+1))
done
if [ ${ind} -gt 0 ]; then
  echo "WARNING: Output file renamed to ${output_name} due to name collision in directory ${output_dir}"
fi

module load singularity/3.6
squash_command="mksquashfs ${topdir} ${output_name} -ef ${exclude_file} -no-progress -noI -noD -noX -keep-as-directory -all-root -processors 1 -no-duplicates -fstime 1601265600"
singularity exec --overlay ${squash_file}:ro ${singularity_image} ${squash_command}