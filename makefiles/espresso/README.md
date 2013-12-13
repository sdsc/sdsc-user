Quantum Espresso Build Tools
============================
This directory contains a few tools to help users of SDSC Gordon build Quantum
Espresso with either OpenMPI or MVAPICH2 and Intel's hardware-accelerated MKL
libraries.

* `build-espresso.sh` - A fully automated build script that will build Quantum Espresso against Intel MKL and OpenMPI
* `make.sys.openmpi` - A version of 'make.sys' that will build against Intel MKL and OpenMPI
* `make.sys.mvapich2` - A version of 'make.sys' that will build against Intel MKL and MVAPICH2

Compatibility Notes
-------------------
The `make.sys` files should also work on XSEDE/SDSC's Trestles resource provided
you do `module swap pgi intel` and `module load mvapich2_ib` or `module load 
openmpi_ib` before trying to build since Intel's compilers are not the default 
on that machine.

Known Issues
------------
Users have reported problems (segmentation faults) for the following cases:

* Gordon: Intel+MVAPICH2 (Intel+OpenMPI was the fix)
* Trestles: PGI+MVAPICH2 (Intel+MVAPICH2 was the fix)

If you run into any issues like this, try using a different compiler or MPI
implementation.  If you need more specific guidance, contact [help@xsede.org](mailto:help@xsede.org).
