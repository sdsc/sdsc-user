This directory contains some sample scripts to illustrate how the job bundler
for SDSC's Gordon and Trestles resources can be used to launch a series of
jobs that use a specific software module like Octave.  The files included are

* tasks.octave - the tasks list that will run 64 octave jobs
* gordon-octave.qsub - an appropriate submit script for Gordon, assuming you
    want to run all 64 octave jobs simultaneously across four nodes
* trestles-octave.qsub - an appropriate submit script for Trestles, assuming
    want to run all 64 octave jobs simultaneously across two nodes
