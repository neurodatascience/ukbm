#!/bin/bash
#SBATCH --array=0
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=8G
#SBATCH --time=1-00:00:00

helpstr="$(basename $0) [-h] [-d depth] [-f format] [-n numim] directory_to_squash
Squashes the specified directory. The number of output SquashFS files is dictated by the number of jobs in the submitted job array (--array to sbatch).

where:
  -h                            Show this message.
  -d, --depth DEPTH		Depth of directory to use for splitting. Default 0. E.g. /neurohub/ukbb/imaging/sub-* would require -d 3.
  -f, --format FORMAT		Formatting string to use for naming output. It should change with '${SLURM_ARRAY_TASK_ID}' to prevent collisions. Default: 'neurohub_ukbb_data_${SLURM_ARRAY_TASK_ID}'. Recommended: 'neurohub_ukbb_MODALITY_sesSESSION_${SLURM_ARRAY_TASK_ID}_STRUCTURE.squashfs'.
				NOTE: input should be specified using single quotes to avoid variable expansion.
  -n, --numim NUMIM		Number of images that would be produced. Default to '${SLURM_ARRAY_TASK_COUNT}'. Only used when a subset needs to be re-squashed. A job that was previously-submitted with --array=0-3 would produce 4 images. If you need to re-squash image 2, you would use: sbatch --array=2 [...] $(basename $0) -n 4 [...].
  --dry				If set, will not squash but will instead print the list of files that would be excluded.
  directory_to_squash		Directory containing the data that needs to be squashed.

Example:
sbatch --account=rpp-account-aa --array=0-5 $(basename $0) -d 3 -f 'neurohub_ukbb_rfmri_ses2_${SLURM_ARRAY_TASK_ID}_bids.squashfs' data/
Resquashing images 2,3:
sbatch --account=rpp-account-aa --array=2-3 $(basename $0) -d 3 -f 'neurohub_ukbb_rfmri_ses2_${SLURM_ARRAY_TASK_ID}_bids.squashfs' -n 6 data/
"

### Parse input
nameformat='neurohub_ukbb_data_${SLURM_ARRAY_TASK_ID}'
splitdepth=0
numim="${SLURM_ARRAY_TASK_COUNT}"
pos_args=()
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo $helpstr
      exit 0
      ;;
    -d|--depth)
      splitdepth="${2}"
      shift 2
      ;;
    -f|--format)
      nameformat="${2}"
      shift 2
      ;;
    -n|--numim)
      numim="${2}"
      shift 2
      ;;
    --dry)
      SLURM_TEST_ONLY=1
      shift 1
      ;;
    -*|--*)
      >&2 echo "Unrecognized option ${1}"
      exit 1
      ;;
    *)
      pos_args+=("$1")
      shift 1
      ;;
  esac
done

squashdir=${pos_args[0]}
echo "squashdir: ${squashdir}"
### Input parsed
ST=${SLURM_TMPDIR}

# Get full path
squashdir=`readlink -f "${squashdir}"`

# Need to create exclusion list for mksquashfs
# Use splitdepth to limit splitting depth
IFS=$'\n' eval 'dirlist=(`find "${squashdir}" -maxdepth ${splitdepth} -mindepth ${splitdepth} | sort`)'
# Split list into even pieces
ndirs=${#dirlist[@]}
nperjob=$((ndirs/numim+1))  # +1 because of bash's flooring
startind=$((SLURM_ARRAY_TASK_ID*nperjob))
#include_list=(${dirlist[@]:startind:nperjob})

# Generate exclude list; add all directories we previously found except for a range
exclude_list=()
exclude_list+=(${dirlist[@]:0:startind})
exclude_list+=(${dirlist[@]:startind+nperjob})
tdir=`mktemp -d -p ${ST} tmp.XXXXXX`
printf "%s\n" ${exclude_list[@]} > ${tdir}/exclude.txt
outname="`eval echo $nameformat`"

if [ -z "${SLURM_TEST_ONLY}" ]; then
	SLURM_TEST_ONLY=0
fi

echo "Total number of files/dirs: ${#dirlist[@]}"
echo "Number in exclude list: ${#exclude_list[@]}"
echo "Difference: $((${#dirlist[@]}-${#include_list[@]}-${#exclude_list[@]}))"
echo "Outname: ${outname}"
if [ "${SLURM_TEST_ONLY}" -eq 1 ]; then
	printf "%s\n" ${exclude_list[@]} > ./exclude_${outname}.txt
	exit 0
fi

mksquashfs ${squashdir} ${outname} -ef ${tdir}/exclude.txt -no-progress -noI -noD -noX -keep-as-directory -all-root -processors 1 -no-duplicates -fstime 1601265600

