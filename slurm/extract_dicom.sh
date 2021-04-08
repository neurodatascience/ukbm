#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --array=0-3
#SBATCH --time=3-00:00:00

ST=${SLURM_TMPDIR}
helpstr="$(basename "$0") [-h] [-s skip_flag] zipdir bidsdir - Slurm submission script to convert UKB diffusion DICOMs into BIDS.

where:
  -h      Show this message.
  -s      Whether to skip a subject if present in output directory (0=don't skip, 1=skip). Defaults to 1.
  zipdir  Directory containing the DICOM zip files to extract
  bidsdir Output directory.
"
skip_flag=1
if [ -z `type -t dcm2niix` ]; then
  module load dcm2niix
fi

if [ -n "${SLURM_TMPDIR}" ]; then
  ST=${SLURM_TMPDIR}
  is_slurm=1
else
  ST=`mktemp -d`
  is_slurm=0
fi

pos_args=()
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "Usage: ${helpstr}"
      exit 0
      ;;
    -s|--skip)
      skip_flag="${2}"
      shift 2
      ;;
    -*|--*)
      echo "Unrecognized option: ${1}"
      exit 1
      ;;
    *)
      pos_args+=("$1")
      shift 1
      ;;
  esac
done

zipdir=${pos_args[0]}
bidsdir=${pos_args[1]}

# Get list of zips
ziplist=(`printf "%s\n" "${zipdir}/*.zip"`)
ziplength=${#ziplist[@]}
njobs=${SLURM_ARRAY_TASK_COUNT}
jobind=${SLURM_ARRAY_TASK_ID}

zipspertask=$((ziplength/njobs+1))

tmptxt=`mktemp`
start_ind=$((jobind*zipspertask))
for z in ${ziplist[@]:start_ind:zipspertask}; do
  echo "${z}" >> ${tmptxt}
done
#end_ind=$((stard_ind+zipspertask-1))

# TODO: fix this pathing
bash ukbm/bashtools/dwi_from_dicom.sh -s ${skip_flag} ${tmptxt} ${bidsdir}