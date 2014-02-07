This directory contains some sample scripts to illustrate how the job bundler
for SDSC's Gordon and Trestles resources can also run multithreaded jobs.
The files included are

* tasks.OpenMP - how your multiple OpenMP jobs may appear in the tasks file
* gordon-OpenMP.qsub - an appropriate submit script for Gordon, assuming you
    are packing two 8-thread jobs per node
* trestles-OpenMP.qsub - an appropriate submit script for Trestles, assuming
    you are packing four 8-thread jobs per node
