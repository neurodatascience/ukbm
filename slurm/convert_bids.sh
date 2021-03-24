#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --array=0-3
#SBATCH --time=1-00:00:00

# This file is a batch submission script for SLURM.
module load python/3.8
helpstr="$(basename "$0") [-h] [--raw_out RAWDIR] [--source_out SOURCEDIR] [--derivatives_out DERIVATIVESDIR] zipdir - Code to extract and fix JSON file for BIDS

where:
  -h | --help     Show this message.
  --raw_out           Directory in which to place raw data.
  --derivatives_out   Directory in which to place derivative data.
  --source_out        Directory in which to place source data.
  zipdir  Directory containing the NIfTI zip files to extract
"

while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "Usage: ${helpstr}"
      exit 0
      ;;
    -r|--raw_out)
      raw_out="${2}"
      shift 2
      ;;
    -d|--derivatives_out)
      derivatives_out="${2}"
      shift 2
      ;;
    -s|--source_out)
      source_out="${2}"
      shift 2
      ;;
    -*|--*)
      echo "Unrecognized option: ${1}"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

zipdir="${1}"

if [ -z ${zipdir} ]; then
  >&2 echo "The directory containing the NIfTI files must be specified"
fi

if [ -z ${raw_out} ] && [ -z ${derivatives_out} ] && [ -z ${source_out} ]; then
  >&2 echo "Output type/location must be specified via raw_out, derivatives_out, or source_out"
  exit 1
fi

ST=${SLURM_TMPDIR}
njobs=${SLURM_ARRAY_TASK_COUNT}
jobind=${SLURM_ARRAY_TASK_ID}

# Get list of zips
echo "Getting zips from ${zipdir}"
ziplist=(`printf "%s\n" ${zipdir}/*.zip`)
zipnum=${#ziplist[@]}
echo "Found ${zipnum} zipped files"

nperjob=$((zipnum/njobs+1))
startind=$((jobind*nperjob))

ziptmp=`mktemp`
for zipname in ${ziplist:startind:nperjob}; do
  echo ${zipname} >> ${ziptmp}
done
dirlist=""
if [ ! -z ${raw_out} ]; then
  dirlist+="--raw_out ${raw_out}"
fi
if [ ! -z ${derivatives_out} ]; then
  dirlist+=" --derivatives_out ${derivatives_out}"
fi
if [ ! -z ${source_out} ]; then
  dirlist+=" --source_out ${source_out}"
fi

python3.8 ukbm/convert/bids.py ${dirlist} --zip_filelist ${ziptmp}