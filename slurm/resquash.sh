#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=8G
#SBATCH --time=1-00:00:00

helpstr="$(basename "$0") [-h] [-p] [-j dataset_description.json] subject_list singularity_img output_dir topdir squashfs - Re-squashes the input SquashFS files without the subjects listed

where:
  -h                            Show this message.
  -p, --participants            If set, find the participants.tsv file, remove withdrawn subjects, and repackage into resquashed output.
  -j, --json
  subject_list                  Text file with subject directories to remove.
  singularity_img               Singularity image to use to mount SquashFS files.
  output_dir                    Path to put resquashed images
  topdir                        Path in SquashFS image to squash.
  squashfs_files                SquashFS files to mount, check, and resquash without the subjects to be removed.
"

pos_args=()
fix_participants=0
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo $helpstr
      exit 0
      ;;
    -p|--participants)
      fix_participants=1
      shift 1
      ;;
    -j|--json)
      dataset_description="${2}"
      shift 2
      ;;
    *)
      pos_args+=("$1")
      shift 1
      ;;
  esac
done

module load singularity/3.7

exclude_file=${pos_args[0]}
singularity_image=${pos_args[1]}
output_dir=${pos_args[2]}
topdir=${pos_args[3]}
squash_file=${pos_args[4]}

ST=${SLURM_TMPDIR}

# Find safe output
raw_output_name=`basename ${squash_file}`
output_name=${raw_output_name}
ind=0
while [ -f ${output_dir}/${output_name} ]; do
  output_name=${raw_output_name%%.*}_${ind}.${output_name#*.}
  ind=$((ind+1))
done
if [ ${ind} -gt 0 ]; then
  echo "WARNING: Output file renamed to ${output_name} due to name collision in directory ${output_dir}"
fi

# If specified, find participants.tsv and remove subjects in exclusion list.
exc_path=`dirname "$(head -n 2 ${exclude_file} | tail -n 1)"`
part_path=${exc_path}/participants.tsv
part_dir=$(dirname ${part_path})
if [ ${part_dir:0:1} == "/" ]; then
    part_dir=${part_dir:1}
fi
mkdir -p ${ST}/${part_dir}
chmod -R o+rx ${ST}/${part_dir}

if [ "${fix_participants}" -eq 1 ]; then
  # extract participants.tsv; store in same path structure for squashing
  singularity exec --overlay ${squash_file}:ro -B ${ST}/${part_dir}:/.st_tmp/ ${singularity_image} cp ${part_path} /.st_tmp/
  # remove subjects from participants.tsv
  if [ -f "${ST}/${part_dir}/participants.tsv" ]; then
    while read -r exc; do
      exc_base=`basename ${exc}`
      sed -i "/${exc_base}/d" ${ST}/${part_dir}/participants.tsv
    done < ${exclude_file}
  else
    fix_participants=0
  fi
fi

# Check for updating dataset_description
if [ -n "${dataset_description}" ]; then
  dataset_file=`basename ${dataset_description}`
  cp ${dataset_description} ${ST}/${part_dir}/${dataset_file}
fi

# If we need to fix either dataset or participants, create new squash for overlay
part_dir_top=${part_dir%%/*}
if [ "${fix_participants}" -eq 1 ] || [ -n "${dataset_description}" ]; then
  squash_command="mksquashfs /to_squash/${part_dir_top} /to_squash/txtfix.squashfs -no-progress -noI -noD -noX -keep-as-directory -all-root -processors 1 -no-duplicates -fstime 1601265600"
  chmod -R o+rx ${ST}/${part_dir_top}
  singularity exec -B ${ST}:/to_squash/ ${singularity_image} ${squash_command}
fi

exclude_filename=`basename ${exclude_file}`
exclude_dir=`dirname ${exclude_file}`
if [ -f "${ST}/txtfix.squashfs" ]; then
  overlay="--overlay ${squash_file}:ro --overlay ${ST}/txtfix.squashfs:ro"
else
  overlay="--overlay ${squash_file}:ro"
fi
cp ${exclude_file} ${ST}/${exclude_filename}

squash_command="mksquashfs ${topdir} /.out/${output_name} -ef /.exclude/${exclude_filename} -no-progress -noI -noD -noX -keep-as-directory -all-root -processors 1 -no-duplicates -fstime 1601265600"
singularity exec ${overlay} -B ${ST}:/.exclude/ -B ${output_dir}:/.out/ ${singularity_image} ${squash_command}

