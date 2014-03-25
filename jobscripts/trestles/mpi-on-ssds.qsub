#!/bin/bash
################################################################################
#  Boilerplate job submit script to run an MPI job on Trestles's node-local
#  solid-state disks (SSDs) and copy the resulting data back to Lustre in a
#  metadata-friendly way
#
#  Glenn K. Lockwood, San Diego Supercomputer Center              January 2014
################################################################################
#PBS -N mpi-ssds
#PBS -l nodes=4:ppn=32
#PBS -l walltime=10:00:00
#PBS -q normal

### ALL of the input files your application will expect in its runtime directory.
### Can use "*" for all files.  Relative to $PBS_O_WORKDIR
INPUT_FILES="in.spce data.spce"

### This is where you enter the contents of your normal submit script, but omit
### the cd to $PBS_O_WORKDIR
my_job() {
  module load lammps
  mpirun_rsh -np 64 -hostfile $PBS_NODEFILE $(which lammps) < in.spce
}

################################################################################
### You shouldn't have to change anything below here ###########################
################################################################################
PARALLEL_COPY=0
LOCAL_SCRATCH=/scratch/$USER/$PBS_JOBID

cd $PBS_O_WORKDIR

### Step 1.  Distribute input data to all nodes (if necessary)
for node in $(/usr/bin/uniq $PBS_NODEFILE)
do
    echo "$(/bin/date) :: Copying input data to node $node"
    if [ $PARALLEL_COPY -ne 0 ]; then
        scp $INPUT_FILES $node:$LOCAL_SCRATCH/
    else
        scp $INPUT_FILES $node:$LOCAL_SCRATCH/ &
    fi
done
wait

cd $LOCAL_SCRATCH

### Step 2.  Run desired code
my_job

estatus=$?
if [ $estatus -ne 0 ]; then
    echo "WARNING: MPI job did not exit cleanly.  We may be copying back garbage." >&2
fi

### Step 3.  Flush contents of each node's SSD back to workdir
nn=0
for node in $(/usr/bin/uniq $PBS_NODEFILE)
do
    echo "$(/bin/date) :: Copying output data from node $node"
    command="cd $LOCAL_SCRATCH && tar cvf $PBS_O_WORKDIR/node$nn-output.tar *"
    if [ $PARALLEL_COPY -ne 0 ]; then
        ssh $node "$command" &
    else
        ssh $node "$command"
    fi
    let "nn++"
done
wait

exit $estatus
