#!/bin/bash

LOG_DIR=$1
for i in $LOG_DIR/*.out; do echo `cat $i | head -2 | tail -1 | cut -d " " -f3` `cat $i | grep "fMRIPrep finished successfully!" | wc -l`; done > slurm_run_outcomes.txt

echo "Saved run outcome in ./slurm_run_outcomes.txt (1 implies successful run)" 
