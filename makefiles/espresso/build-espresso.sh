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

### Detect whether we are using MVAPICH2 or OpenMPI
if [[ $LOADEDMODULES == *mvapich2_ib* ]]; then
  MPI_STACK=mvapich2
elif [[ $LOADEDMODULES == *openmpi_ib* ]]; then
  MPI_STACK=openmpi
else
    echo "Unknown MPI module.  Please either load mvapich2_ib or openmpi_ib."
    exit 1
fi

### Detect whether we are using Intel or PGI compilers
if [[ $LOADEDMODULES == *intel* ]]; then
  COMPILER=intel
  CC=icc
  CXX=icpc
  F77=ifort
  FC=ifort
elif [[ $LOADEDMODULES == *pgi* ]]; then
  COMPILER=pgi
  CC=pgcc
  CXX=pgc++
  F77=pgf77
  FC=pgf90
else
    echo "Unknown compiler.  Please either load intel or pgi."
    exit 1
fi

### Unload any extraneous modules
module purge
module load gnubase $COMPILER ${MPI_STACK}_ib 

make distclean

### PGI users should use our FFTW3 module before autoconf
if [ "z$COMPILER" == "zpgi" ]; then
  module load fftw
  LDFLAGS="$LDFLAGS -L $FFTWHOME/lib -lfftw3 -L $PGIHOME/libso"
fi

### Generate a reasonable starting point for make.sys
./configure \
    CC=$CC \
    CXX=$CXX \
    F77=$F77 \
    FC=$FC \
    CFLAGS="$CFLAGS" \
    FFLAGS="$FFLAGS" \
    LDFLAGS="$LDFLAGS"

cp make.sys make.sys.bak

if [ "z$COMPILER" == "zintel" ]; then
  ### Ensure that MKL's bindings are used for FFTs and LAPACK
  blas_libs=$(grep '^BLAS_LIBS *=' make.sys | cut -d= -f2)
  sed -i 's/-D__FFTW[^3]/-D__FFTW3 /' make.sys
  sed -i "s/^FFT_LIBS *=.*$/FFT_LIBS = $blas_libs/" make.sys
  sed -i "s/^LAPACK_LIBS *=.*$/LAPACK_LIBS = $blas_libs/" make.sys

  ### Need to manually specify Intel MPI (MVAPICH2) ScaLAPACK library to fix the
  ### incorrectly autodetected openmpi ScaLAPACK
  if [ "z$MPI_STACK" == "zmvapich2" ]; then
    sed -i 's/mkl_blacs_openmpi_lp64/mkl_blacs_intelmpi_lp64/' make.sys
  fi

  ### Disable MKL ScaLAPACK if using OpenMPI due to performance problems with 
  ### OpenMPI and ScaLAPACK 
  if [ "z$MPI_STACK" == "zopenmpi" ]; then
    sed -i 's/-D__SCALAPACK//' make.sys
  fi
elif [ "z$COMPILER" == "zpgi" ]; then
  ### There are known conflicts between PGI and the IOTK library used by 
  ### ESPRESSO
  sed -i 's/^DFLAGS\(.*\)$/DFLAGS\1 -D__IOTK_WORKAROUND1/' make.sys
fi

### Perform the build
make pw #all

### Check for errors
if [ $? -ne 0 ]; then
  echo "" >&2
  echo "It looks like the build process failed!  Please contact help@xsede.org for futher assistance." >&2
  echo "" >&2
  exit 5
fi
