#!/bin/bash

# This code converts UKB DWI dicomes into BIDS

helpstr="$(basename "$0") [-h] [-s skip_flag] zipfilelist bidsdir - Code to convert UKB diffusion DICOMs into BIDS.

where:
  -h            Show this message.
  -s            Whether to skip a subject if present in output directory (0=don't skip, 1=skip). Defaults to 1.
  zipfilelist   Text file with newline-delimited list of zipped DWI DICOMs.
  bidsdir       Output directory.
"


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
skip_flag=1
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

# first pos_arg = file_list
file_list=${pos_args[0]}
save_dir=${pos_args[1]}

while read -r fil; do
  zipname=`basename $fil`
  filename=`echo ${zipname%.zip}`
  filesplit=(${filename//_/ })
  subid=${filesplit[0]}
  datafield=${filesplit[1]}
  session=${filesplit[2]}

  outdir="${ST}/${subid}_${session}"
  if [ -d ${outdir} ] && [ ${skip_flag} -eq 1 ]; then
    echo "Skipping ${zipname}"
    continue
  fi
  mkdir ${outdir}
  # unzip dcm into tmp
  unzip -q -d ${outdir} ${fil}
  # convert to nii
  dcm2niix -b y -f '%p_%s' -z y -o ${outdir} ${outdir}

  # only take files which have bvec + bval
  for bv in `printf "%s\n" "${outdir}/*.bval"`; do
    bvec=${bv%.bval}.bvec
    if [ -f ${bvec} ]; then
      # sequence has both bvec, bval. Convert!
      conv_base=${bv%.bval}
#      echo "base: ${conv_base}"
      seqbase=`basename ${conv_base}`
      seqsplit=(${seqbase//_/ })
#      echo "seqsplit: ${seqsplit[@]}"
#      echo "seqsplit[1]: ${seqsplit[1]}"
      acq_dir=${seqsplit[1]}
      bids_dir="${save_dir}/sub-${subid}/ses-${session}/dwi/"
      mkdir -p ${bids_dir}
      bids_pref="sub-${subid}_ses-${session}_acq-${acq_dir}_dwi"
      dev_dest=`df ${bids_dir} | awk 'FNR == 2 { print $1 }'`
      for conv in $(printf "%s\n" "${conv_base}*"); do
#        echo "conv: ${conv}"
#        echo "dest: ${bids_dir}"
        # get suffix
        convbasename=`basename ${conv}`
        suff=${convbasename#*.}
        # check device for mv vs. cp
        dev_source=`df ${conv} | awk 'FNR == 2 { print $1 }'`
        if [ ${dev_source} = ${dev_dest} ]; then
          # this is not typically needed since 'mv' defaults to 'cp' across filesystems, but I've had issues with this before
          mv ${conv} ${bids_dir}/${bids_pref}.${suff}
        else
          cp ${conv} ${bids_dir}/${bids_pref}.${suff}
        fi
	rm -r ${conv}
      done
    fi
  done
done < ${file_list}
