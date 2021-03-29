#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4096M
#SBATCH --time=0-01:00:00

# The supplied .bval and .bvec files are tab-delimited instead of space. This swaps tabs for spaces.

helpstr="$(basename "$0") [-h] bidsdir - Code to fix formatting of bvec / bval files.

where:
  -h        This help message.
  bidsdir   Top-level directry for the BIDS data.
"


while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "${helpstr}"
      exit 0
      ;;
    -*|--*)
      echo "Unrecognized option: $1"
      exit 1
      ;;
  esac
done

bidsdir="${1}"

for bv in `find ${bidsdir} -name "*.bv*" -type f`; do
  sed -i 's/\t/ /g' ${bv}
done