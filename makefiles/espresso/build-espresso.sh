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

USE_FFTW=0
USE_NETLIB=0
ESPRESSO_TARGETS=all

### Detect whether we are using MVAPICH2 or OpenMPI
if [[ $LOADEDMODULES == *mvapich2_ib* ]]; then
  MPI_STACK=mvapich2
elif [[ $LOADEDMODULES == *mv2profile_ib* ]]; then
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
echo "*** Using $COMPILER and $MPI_STACK"
module load gnubase $COMPILER ${MPI_STACK}_ib 

### Reset source tree to pristine state
make veryclean

CONFIG_PARAMS=""

################################################################################
### Intel compiler 
################################################################################
if [ "z$COMPILER" == "zintel" ]; then

  if [ $USE_FFTW -ne 0 ]; then
    echo "*** Using FFTW3 for FFTs"
    module load fftw 
    export FFT_LIBS="-L$FFTWHOME/lib -lfftw3"
  else
    echo "*** Using MKL for FFTs"
    # This is a little hairy because it also loads up objects for BLAS.  We rely
    # on the Netlib libraries overwriting the namespace if we want to use Netlib
    # for BLAS/LAPACK by careful ordering at link time.
    export FFT_LIBS="-lmkl_intel_lp64 -lmkl_sequential -lmkl_core"
  fi

  if [ $USE_NETLIB -ne 0 ]; then
    echo "*** Using Netlib BLAS/LAPACK"
    module load lapack
    module load scalapack
    export BLAS_LIBS="-L$LAPACKHOME/lib -lblas"
    export LAPACK_LIBS="-L$LAPACKHOME/lib -llapack"
    if [ "z$SCALAPACKHOME" == "z" ]; then
      # as of Jan 3, 2013, we do not provide ScaLAPACK for PGI+OpenMPI
      echo "*** No ScaLAPACK available for $COMPILER with $MPI_STACK" >&2
      module unload scalapack
    else 
      echo "*** Using Netlib ScaLAPACK"
      export SCALAPACK_LIBS="-L$SCALAPACKHOME/lib -lscalapack"
    fi
  else
    ### MKL for BLAS/LAPACK and ScaLAPACK provides best performance
    echo "*** Using MKL for BLAS/LAPACK"
    export BLAS_LIBS="-lmkl_intel_lp64 -lmkl_sequential -lmkl_core"
    if [ "z$MPI_STACK" == "zmvapich2" ]; then
      echo "*** Using MKL for ScaLAPACK"
      export SCALAPACK_LIBS="-lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64"
    elif [ "z$MPI_STACK" == "zopenmpi" ]; then
      echo "*** Using MKL for ScaLAPACK"
      export SCALAPACK_LIBS="-lmkl_scalapack_lp64 -lmkl_blacs_openmpi_lp64"
      ### OpenMPI + ScaLAPACK performs very poorly for small core counts.  You may
      ### disable it by uncommenting the following line
#     CONFIG_PARAMS="$CONFIG_PARAMS --without-scalapack"
    else
      echo "*** No ScaLAPACK available for $COMPILER with $MPI_STACK" >&2
      module unload scalapack
      export SCALAPACK_LIBS=""
      CONFIG_PARAMS="$CONFIG_PARAMS --without-scalapack"
    fi
  fi

################################################################################
### PGI compiler
################################################################################
elif [ "z$COMPILER" == "zpgi" ]; then

  ### Load FFT library FFTW3 (default) or ACML
  if [ $USE_FFTW -ne 0 ]; then
    echo "*** Using FFTW3 for FFTs"
    module load fftw 
    export FFT_LIBS="-L$FFTWHOME/lib -lfftw3"
  else
    echo "*** Using ACML for FFTs"
    export FFT_LIBS="-L$PGIHOME/libso -lacml"
  fi

  ### You may use either Netlib's BLAS+LAPACK or the ACML version with PGI
  if [ $USE_NETLIB -ne 0 ]; then
    echo "*** Using Netlib BLAS/LAPACK"
    module load lapack
    export BLAS_LIBS="-L$LAPACKHOME/lib -lblas"
    export LAPACK_LIBS="-L$LAPACKHOME/lib -llapack"
  else
    echo "*** Using ACML for BLAS/LAPACK"
    export BLAS_LIBS="-L$PGIHOME/libso -lacml"
    export LAPACK_LIBS="-L $PGIHOME/libso -lacml"
  fi

  ### ScaLAPACK loads on top of ACML
  module load scalapack
  if [ "z$SCALAPACKHOME" == "z" ]; then
    # as of Jan 3, 2013, we do not provide ScaLAPACK for PGI+OpenMPI.  I have
    # it built on the Gordon side for adventurous users, but this is not 
    # officially supported.
    #export SCALAPACK_LIBS="-L/home/glock/apps/scalapack-2.0.2/pgi/openmpi -lscalapack"
    echo "*** No ScaLAPACK available for $COMPILER with $MPI_STACK" >&2
    module unload scalapack
  else 
    echo "*** Using Netlib ScaLAPACK"
    export SCALAPACK_LIBS="-L$SCALAPACKHOME/lib -lscalapack"
  fi
fi

### Generate a reasonable starting point for make.sys
./configure \
    $CONFIG_PARAMS \
    CC=$CC \
    CXX=$CXX \
    F77=$F77 \
    FC=$FC \
    CFLAGS="$CFLAGS" \
    FFLAGS="$FFLAGS" \
    LDFLAGS="$LDFLAGS"

cp make.sys make.sys.bak

if [ "z$COMPILER" == "zintel" ]; then
  ### Disable MKL ScaLAPACK if using OpenMPI due to performance problems with 
  ### OpenMPI and ScaLAPACK 
# if [ "z$MPI_STACK" == "zopenmpi" ]; then
#   sed -i 's/-D__SCALAPACK//' make.sys
# fi
  /bin/true
elif [ "z$COMPILER" == "zpgi" ]; then
  ### There are known conflicts between PGI and the IOTK library used by 
  ### ESPRESSO
  sed -i 's/^DFLAGS\(.*\)$/DFLAGS\1 -D__IOTK_WORKAROUND1/' make.sys
  /bin/true
fi

### Fix autoconf automatically picking up /usr/lib/libfftw3.so
if [ $USE_FFTW -eq 0 ]; then
    sed -i 's/-lfftw3//g' make.sys
fi

### Perform the build
make $ESPRESSO_TARGETS

### Check for errors
if [ $? -ne 0 ]; then
  echo "" >&2
  echo "It looks like the build process failed!  Please contact help@xsede.org for futher assistance." >&2
  echo "" >&2
  exit 5
fi
