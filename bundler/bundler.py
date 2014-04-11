#!/usr/bin/env python
################################################################################
#  bundler.py - Pack multiple serial jobs into a single job script
#
#  Glenn K. Lockwood, San Diego Supercomputer Center             November 2013
################################################################################
import os
import sys
import socket

try:
    tasksfile = sys.argv[1]
    TF = open( os.path.abspath(tasksfile), 'r' )
except IOError:
    sys.stderr.write( "Unable to open tasks file %s\n" % tasksfile )

hostname = socket.gethostname()

### We can use pbsdsh instead of MPI if the bundled tasks themselves need MPI.
### Using Torque's TM interface to launch tasks is very ugly because they start
### with bare environments.  This is how you might want to run:
### $ pbsdsh /usr/bin/env BUNDLER_MODE=pbsdsh PBS_NP=$PBS_NP PATH=$PATH \
###                       LD_LIBRARY_PATH=$LD_LIBRARY_PATH $(which python-mpi) \
###                       $PWD/bundler.py $PWD/TASKS
if ('BUNDLER_MODE' in os.environ 
and os.environ['BUNDLER_MODE'].lower() == "pbsdsh"):
    myid = int(os.environ['PBS_VNODENUM'])
    numprocs = int(os.environ['PBS_NP'])
    taskmgr = "pbsdsh worker"

### Otherwise use MPI.  Initialize it here
else:
    ### Initialize MPI information
    if hostname.startswith( 'trestles' ):
        sys.path.append(r'/home/diag/opt/mpi4py/mvapich2/gnu/1.3.1/lib/python')
    elif hostname.startswith( 'gcn' ) or hostname.startswith( 'gordon' ):
        sys.path.append(r'/home/diag/opt/mpi4py/mvapich2/intel/1.3.1/lib/python')
    from mpi4py import MPI
    comm = MPI.COMM_WORLD
    myid = comm.Get_rank()
    numprocs = comm.Get_size()
    taskmgr = "MPI process"

### Read in tasks to be executed
print "Got %d task slots" % numprocs
tasks = TF.readlines()
ntasks = len(tasks)
TF.close()

### Launch my assigned task(s)
for i in range(ntasks):
    if myid == (i % numprocs):
        task = tasks[i]
        task = task.rstrip()
        print "%s %d on %s running task [%s]" % (taskmgr, myid, hostname, task)
        os.system(task)

try:
    MPI.Finalize()
except NameError:
    pass
