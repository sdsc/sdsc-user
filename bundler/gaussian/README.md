This directory contains some sample scripts to illustrate how the job bundler
for SDSC's Gordon and Trestles resources can run multiple Gaussian jobs all
in a single job submission.

Of note, this example also shows that the bundler works even if your number of 
cores does not evenly divide into the core count you request (e.g., we want to 
run five Gaussian jobs each using %nproc=8, for a total of 40 cores, but are 
requesting 48 cores in gordon-gaussian.qsub or 64 cores in 
trestles-gaussian.qsub)

The files included are

* tasks.gaussian - how your multiple OpenMP jobs may appear in the tasks file
* gordon-gaussian.qsub - an appropriate submit script for Gordon, assuming you
    are packing two Gaussian jobs per node with %nproc=8
* trestles-gaussian.qsub - an appropriate submit script for Trestles, assuming
    you are packing four Gaussian jobs per node with %nproc=8
