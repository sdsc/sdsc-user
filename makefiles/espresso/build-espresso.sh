#!/bin/bash
################################################################################
#  Meta-build process to compile Quantum Espresso on XSEDE/SDSC's Gordon and
#  Trestles resources.
#
#  This script should run out of your Quantum Espresso source tree.  Tested with
#  version 5.0.1 and 5.0.3 on SDSC Gordon and Trestles
#
#  Glenn K. Lockwood, San Diego Supercomputer Center             December 2013
################################################################################

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

### Reset source tree to pristine state
make veryclean

### PGI relies on external libraries which must be passed to autoconf
if [ "z$COMPILER" == "zpgi" ]; then

  # Load FFT library (FFTW3)
  module load fftw 
  export FFT_LIBS="-L $FFTWHOME/lib -lfftw3"

  # Load basic linear algebra subroutines (BLAS) 
  # We provide ACML or Netlib (no ATLAS installed)
  export BLAS_LIBS="-L $PGIHOME/libso -lacml"
# module load lapack
# export BLAS_LIBS="-L $LAPACKHOME/lib -lblas"

  # LAPACK
  export LAPACK_LIBS="-L$LAPACKHOME/lib -llapack"

  # ScaLAPACK
  module load scalapack
  if [ "z$SCALAPACKHOME" == "z" ]; then
    # as of Jan 3, 2013, we do not provide ScaLAPACK for PGI+OpenMPI
    echo "No ScaLAPACK available for $COMPILER with $MPI_STACK" >&2
    module unload scalapack
  else 
    # ScaLAPACK supercedes LAPACK
    export SCALAPACK_LIBS="-L$SCALAPACKHOME/lib -lscalapack"
    module unload lapack
    export LAPACK_LIBS=""
  fi
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
# if [ "z$MPI_STACK" == "zopenmpi" ]; then
#   sed -i 's/-D__SCALAPACK//' make.sys
# fi
elif [ "z$COMPILER" == "zpgi" ]; then
  ### There are known conflicts between PGI and the IOTK library used by 
  ### ESPRESSO
  sed -i 's/^DFLAGS\(.*\)$/DFLAGS\1 -D__IOTK_WORKAROUND1/' make.sys
fi

### Perform the build
make all

### Check for errors
if [ $? -ne 0 ]; then
  echo "" >&2
  echo "It looks like the build process failed!  Please contact help@xsede.org for futher assistance." >&2
  echo "" >&2
  exit 5
fi
