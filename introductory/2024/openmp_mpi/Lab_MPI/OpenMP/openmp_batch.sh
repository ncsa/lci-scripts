#!/bin/bash

#SBATCH --job-name=OMP_run
#SBATCH --output=slurm.out
#SBATCH --error=slurm.err
#SBATCH --partition=lcilab
#SBATCH --ntasks-per-node=2


myrun=heated_plate.x                          # executable to run

export OMP_NUM_THREADS=$SLURM_JOB_CPUS_PER_NODE  # assign the number of threads
MYHDIR=$SLURM_SUBMIT_DIR            # directory with input/output files 
MYTMP="/tmp/$USER/$SLURM_JOB_ID"    # local scratch directory on the node
mkdir -p $MYTMP                     # create scratch directory on the node  
cp $MYHDIR/$myrun  $MYTMP           # copy all input files into the scratch
cd $MYTMP                           # run tasks in the scratch 

./$myrun > run.out-$SLURM_JOB_ID

cp $MYTMP/run.out-$SLURM_JOB_ID  $MYHDIR      # copy everything back into the home dir
rm -rf  $MYTMP                      # remove scratch directory

