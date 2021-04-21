#!/bin/bash

# This code converts UKB DWI dicomes into BIDS

helpstr="$(basename "$0") [-h] [-s skip_flag] [-p permission] zipfilelist bidsdir - Code to convert UKB diffusion DICOMs into BIDS.

where:
  -h              Show this message.
  -s              Whether to skip a subject if present in output directory (0=don't skip, 1=skip). Defaults to 1.
  -p, --perm PERM Set permission of output file to PERM. E.g.: 700, o+rx, 744.
  zipfilelist     Text file with newline-delimited list of zipped DWI DICOMs.
  bidsdir         Output directory.
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
    -p|--perm)
      perm="${2}"
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

# Make nii staging directory
nii_out=${save_dir}/.nii/


while read -r fil; do
  zipname=`basename $fil`
  filename=`echo ${zipname%.zip}`
  filesplit=(${filename//_/ })
  subid=${filesplit[0]}
  datafield=${filesplit[1]}
  session=${filesplit[2]}

  # output/staging directories
  outdir="${ST}/${subid}_${session}"
  bids_dir="${save_dir}/sub-${subid}/ses-${session}/dwi/"
  nii_tmp="${nii_out}/sub-${subid}_ses-${session}/"


  if [ -d ${bids_dir} ] && [ ${skip_flag} -eq 1 ]; then
    echo "Skipping ${zipname}"
    continue
  fi
  mkdir -p ${bids_dir}
  mkdir ${outdir}
  mkdir -p ${nii_out}
  mkdir -p ${nii_tmp}
  # unzip dcm into tmp
  unzip -q -d ${outdir} ${fil}
  # convert to nii
  dcm2niix -b y -f '%p_%s' -z y -o ${nii_tmp} ${outdir}
  rm -r ${outdir} &

  # only take files which have bvec + bval
  for bv in `printf "%s\n" "${nii_tmp}/*.bval"`; do
    bvec=${bv%.bval}.bvec
    if [ -f ${bvec} ]; then
      # sequence has both bvec, bval. Convert!
      conv_base=${bv%.bval}
      seqbase=`basename ${conv_base}`
      seqsplit=(${seqbase//_/ })
      # get acquisition dir
      if [[ "${seqbase}" =~ .*"_AP_".* ]] && [[ ! "${seqbase}" =~ .*"_PA_".* ]]; then
        acq_dir="AP"
      elif [[ ! "${seqbase}" =~ .*"_AP_".* ]] && [[ "${seqbase}" =~ .*"_PA_".* ]]; then
        acq_dir="PA"
      else
        >&2 echo "Error with ${zipname}; acquisition direction not detected. Skipping"
        break
      fi
      bids_pref="sub-${subid}_ses-${session}_acq-${acq_dir}_dwi"
      for conv in $(printf "%s\n" "${conv_base}*"); do
        # get suffix
        convbasename=`basename ${conv}`
        suff=${convbasename#*.}
        # check device for mv vs. cp
        mv ${conv} ${bids_dir}/${bids_pref}.${suff}
      done
    fi
  done
  if [ -n "${perm}" ]; then
    chmod ${perm} ${bids_dir}/*
  fi
  rm -r ${nii_tmp} &
done < ${file_list}