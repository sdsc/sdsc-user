Gordon Job Submission Scripts
=============================
These are example job submission scripts for a few popular software packages to be used on [XSEDE/SDSC's Gordon resource](http://www.sdsc.edu/us/resources/gordon/).  Consult the wiki for this repository for the most up-to-date information.

Quantum Chemistry
-----------------
* `espresso.qsub` - [Quantum Espresso 5.x](http://www.quantum-espresso.org/)
* `g09job.qsub` - [Gaussian](http://www.gaussian.com/) standard submit script.  Use this unless you have a specific reason to use the script below.
* `g09job-backup.qsub` - [Gaussian](http://www.gaussian.com/) with periodic backup of SSD contents.  Do not use unless you have a good reason to.
* `qchem.qsub` - [QChem 4.x](http://www.q-chem.com/)

Molecular Dynamics
------------------
* `lammps.qsub` - [LAMMPS 17Jun13](http://lammps.sandia.gov/)

Structural Mechanics
--------------------
* `abaqus.qsub` - [Abaqus 6.x](http://www.3ds.com/products-services/simulia/portfolio/abaqus)

Hadoop
------
These scripts will help you run interactive, semi-persistent Hadoop clusters on Gordon with which you can interact directly using the command line.  We provide these at our Hadoop training workshops and are the easiest way to get started using Hadoop on Gordon.

* `hadoop-cluster.qsub` - See documentation at top of script for more information on how to use.
