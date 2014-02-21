Trestles Job Submission Scripts
===============================
These are example job submission scripts for a few popular software packages to be used on [XSEDE/SDSC's Trestles resource](http://www.sdsc.edu/us/resources/trestles/).  Consult the wiki for this repository for the most up-to-date information.

Quantum Chemistry
-----------------
* `g09job.qsub` - [Gaussian](http://www.gaussian.com/) standard submit script.  Use this unless you have a specific reason to use the script below.
* `g09job-backup.qsub` - [Gaussian](http://www.gaussian.com/) with periodic backup of SSD contents.  Do not use unless you have a good reason to.
* `qchem.qsub` - [QChem 4.x](http://www.q-chem.com/)
* `vasp.qsub` - [VASP 4.x and 5.x](https://www.vasp.at/)

Molecular Dynamics
------------------
* `lammps.qsub` - [LAMMPS 19Sep13](http://lammps.sandia.gov/)

Structural Mechanics
--------------------
* `abaqus.qsub` - [Abaqus 6.x](http://www.3ds.com/products-services/simulia/portfolio/abaqus)
