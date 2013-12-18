Quantum Espresso Build Tools
============================
This directory contains a few tools to help users of SDSC's Gordon and Trestles
resources build Quantum Espresso 5.0 with either OpenMPI or MVAPICH2 and 
Intel's hardware-accelerated MKL libraries.

* `build-espresso.sh` - A fully automated build script that will build Quantum Espresso against Intel MKL.  Offers your choice of MVAPICH2 (recommended and default) or OpenMPI (not recommended, not default)
* `make.sys.mvapich2` - A version of 'make.sys' that will build against Intel MKL and MVAPICH2 (same as the one produced by build-espresso.sh; uses MKL's FFTW3 and ScaLAPACK)
* `make.sys.openmpi` - A version of 'make.sys' that will build against Intel MKL and OpenMPI (same as the one produced by build-espresso.sh; uses MKL's FFTW3 and serial LAPACK)

Compatibility Notes
-------------------
The `make.sys` files should also work on XSEDE/SDSC's Trestles resource provided
you do `module swap pgi intel` and `module load mvapich2_ib` or `module load 
openmpi_ib` before trying to build and subsequently run.  This is required 
because Intel's compilers are not the default on that machine.

Known Issues
------------
Users have reported problems (segmentation faults) for the following cases:

* Gordon: Users are reporting issues with binaries compiled against mvapich2.  We have been unable to confirm this.
* Trestles: PGI compilers are known to conflict with Quantum ESPRESSO's IOTK library.  If you experience segmentation violations when ESPRESSO tries to write its output, you are hitting this error.  You should build against -D__IOTK_WORKAROUND1, -D__IOTK_SAFEST, and/or -O3 to work around this particular error; however, be forewarned that performance may remain suboptimal due to problems with the ACML library that ships with PGI.  Use PGI to compile Quantum Espresso at your own risk!

If you run into any issues like this, try using a different compiler or MPI
implementation.  If you need more specific guidance, contact [help@xsede.org](mailto:help@xsede.org).
