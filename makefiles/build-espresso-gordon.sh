#!/bin/bash
################################################################################
#  Meta-build process to compile Quantum Espresso on XSEDE/SDSC Gordon
#  NOT THOROUGHLY TESTED--report issues to help@xsede.org attn: Glenn
#
#  Glenn K. Lockwood, San Diego Supercomputer Center             November 2013
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
#  version 5.0.1 on SDSC Gordon

module purge
module load intel openmpi_ib gnubase

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

make -j16 all || make all
