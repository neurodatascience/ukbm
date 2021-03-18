#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --array=0-9
#SBATCH --time=0-04:00:00

# This file is a batch submission script for SLURM.

while (( "$#" )); do
  case "$1" in
    -




ST=${SLURM_TMPDIR}
