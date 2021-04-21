#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4096M
#SBATCH --time=1-00:00:00
#SBATCH -J dwi_fix

# The supplied .bval and .bvec files are tab-delimited instead of space. This swaps tabs for spaces.

helpstr="$(basename "$0") [-h] bidsdir - Code to fix formatting of bvec / bval files.

where:
  -h        This help message.
  bidsdir   Top-level directry for the BIDS data.
"

pos_args=()
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
    *)
      pos_args+=("$1")
      shift 1
      ;;
  esac
done

bidsdir="${1}"
echo "Checking ${bidsdir}..."
for bv in `find ${bidsdir} -name "*.bv*" -type f`; do
  sed -i 's/\t/ /g' ${bv}
done

echo "Done."