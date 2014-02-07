This directory contains some sample scripts to illustrate how the job bundler
for SDSC's Gordon and Trestles resources can be used to launch a massive number
of short-running tasks as a single job submission.

In this particular example, we are running 900 single-core jobs using only
128 cores.  When the number of tasks in the tasks list is larger than the
number of cores allocated to the job, the task list will be evenly divided
among all cores, and each core will work through its own tasks one by one.

For example, with 900 tasks and only 128 cores,
* core0 will process task 1, then task 129, then task 257, etc.
* core1 will process task 2, then task 130, then task 258, etc.
* core2 will process task 3, then task 131, then task 259, etc.

You can estimate the walltime your entire job will need with this formula:

(# tasks) * (walltime per task in hours) / (16 or 32 cores per node) / (# nodes)

and then adjust your #PBS -l walltime= line accordingly.

This directory contains the following files:

* tasks.massive - the tasks list that will run 900 python jobs
* gordon-massive.qsub - an appropriate submit script for Gordon, assuming you
    want to use 128 cores (8 nodes, 16 cores per node)
* trestles-massive.qsub - an appropriate submit script for Trestles, assuming
    you want to use 128 cores (4 nodes, 32 cores per node)
