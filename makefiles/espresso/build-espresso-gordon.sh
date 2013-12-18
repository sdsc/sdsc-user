#!/bin/bash
################################################################################
#  Meta-build process to compile Quantum Espresso on XSEDE/SDSC's Gordon and
#  Trestles resources.
#
#  Glenn K. Lockwood, San Diego Supercomputer Center             December 2013
################################################################################
#
#  This script automates the following process:
#
#  1. First do a ./configure with Intel compilers.  MKL will be picked up and
#     used for BLAS and SCALAPACK.  To enable it for FFTW3 and LAPACK, you'll
#     need to edit make.sys and
#  2. Replace the -D__FFTW definition with -D__FFTW3
#  3. Copy the contents of BLAS_LIB to LAPACK_LIB
#
#  This script should run out of your Quantum Espresso source tree.  Tested with
#  version 5.0.1 and 5.0.3 on SDSC Gordon and Trestles

### Choose either mvapich2 or OpenMPI.  mvapich2 is recommended.
MPI_STACK=mvapich2
#MPI_STACK=openmpi

module purge
module load gnubase intel ${MPI_STACK}_ib 

make distclean

./configure \
    CC=icc \
    CXX=icpc \
    F77=ifort \
    FC=ifort \
    CFLAGS="" \
    FFLAGS=""
    LDFLAGS=""
    LIBS=""

cp make.sys make.sys.bak

blas_libs=$(grep '^BLAS_LIBS *=' make.sys | cut -d= -f2)

sed -i 's/-D__FFTW[^3]/-D__FFTW3 /' make.sys
sed -i "s/^FFT_LIBS *=.*$/FFT_LIBS = $blas_libs/" make.sys
sed -i "s/^LAPACK_LIBS *=.*$/LAPACK_LIBS = $blas_libs/" make.sys

### Special hack -- disable MKL ScaLAPACK if using OpenMPI due to performance
###  problems with  MKL's bundled ScaLAPACK bindings
if [ "z$MPI_STACK" == "zopenmpi" ]; then
  sed -i 's/-D__SCALAPACK//' make.sys
fi

### Need to manually specify Intel MPI (MVAPICH2) ScaLAPACK library to fix the
### incorrectly autodetected openmpi ScaLAPACK
if [ "z$MPI_STACK" == "zmvapich2" ]; then
  sed -i 's/mkl_blacs_openmpi_lp64/mkl_blacs_intelmpi_lp64/' make.sys
fi

make all
