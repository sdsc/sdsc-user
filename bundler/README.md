This directory contains all of the files necessary to submit "bundled" jobs to
SDSC Gordon or Trestles.  The files are

* bundler.py - this is the job controller script that interfaces MPI with your 
  octave script.  You should not have to modify this unless you know exactly
  what you are doing
* tasks - this is a text file that contains one line for each invocation of 
  the sub-tasks you want to run.  If you want to run sixteen sub-tasks, 
  there should be sixteen lines in this "tasks" file.  The lines can be 
  arbitrarily complex if you want; for example, you can put multiple commands 
  on a single line if you separate them with ;, per bash convention.
* gordon.qsub - this is the script that illustrates how to submit a bundled 
  job to Gordon
* trestles.qsub - this is the script that illustrates how to submit a bundled 
  job to Trestles

This particular example calls an Octave (Matlab) script with several different
input parameters.  The octave module needs to be loaded in the submit script,
but if your application does not need any special modules, you can remove the
relevant `module load octave` line from your `.qsub` file.

To change the number of bundled sub-tasks, you must

1. Modify your "tasks" file to contain the correct number of lines, each one
   representing a sub-task
2. Modify your submit script (gordon.qsub or trestles.qsub) and change your 
   `-l nodes=X:ppn=Y` to request the correct number of nodes and processors 
   per node.  It is OK to request more cores than you have tasks (e.g., 
   request `-l nodes=2:ppn=16` if you only have 24 tasks)
