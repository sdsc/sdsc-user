#define _GNU_SOURCE

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sched.h>
#if !defined(NO_MPI)
  #include <mpi.h>
#else
  #define MPI_COMM_WORLD 0
  void MPI_Init( int *argc, char ***argv ) { return; }
  void MPI_Barrier( int comm ) { return; }
  void MPI_Finalize( void ) { return; }
  void MPI_Comm_rank( int comm, int *rank ) { *rank = 0; return; }
  void MPI_Comm_size( int comm, int *rank ) { *rank = 1; return; }
#endif

void print_hello( int mpi_rank, int mpi_size );

int main ( int argc, char** argv )
{
    int i;
    int mpi_rank, mpi_size;

    MPI_Init( &argc, &argv );
    MPI_Comm_rank( MPI_COMM_WORLD, &mpi_rank );
    MPI_Comm_size( MPI_COMM_WORLD, &mpi_size );

    /* done this way to make sure the output is sorted */
    for ( i = 0; i < mpi_size; i++ ) {
        if ( i == mpi_rank ) {
            print_hello( mpi_rank, mpi_size );
        }
        MPI_Barrier( MPI_COMM_WORLD );
    }

    MPI_Finalize();
    return 0;
}

#define STRING_SIZE 1024
void print_hello( int mpi_rank, int mpi_size )
{

    char host[STRING_SIZE];
    gethostname( host, STRING_SIZE );
    #pragma omp parallel
    {
        int i, count;
        char buffer[STRING_SIZE];
        char mybuf[STRING_SIZE] = "";
        cpu_set_t my_cpuset;

#if defined(_OPENMP) 
        snprintf( buffer, STRING_SIZE, 
            "Hello from thread %2d of %2d in rank %3d of %3d running on cpu %2d[",
            omp_get_thread_num(), 
            omp_get_num_threads(),
            mpi_rank, 
            mpi_size, 
            sched_getcpu() );
#else
        snprintf( buffer, STRING_SIZE, 
            "Hello from rank %3d of %3d running on cpu %2d[",
            mpi_rank, 
            mpi_size, 
            sched_getcpu() );
#endif

        /* convert the cpuset into a string */
        sched_getaffinity(0, sizeof(cpu_set_t), &my_cpuset);
        for (i = 0, count = 0; i < CPU_SETSIZE; i++ )
        {
            if ( CPU_ISSET( i, &my_cpuset ) )
            {
                char mybuf[STRING_SIZE];
                *mybuf = '\0';
                if ( count++ > 0 ) strncat(buffer, ",", STRING_SIZE );
                snprintf( mybuf, STRING_SIZE, "%d", i );
                strncat(buffer, mybuf, STRING_SIZE );
            }
        }

        snprintf(mybuf, STRING_SIZE,  "] on %s\n", host );
        strncat(buffer, mybuf, STRING_SIZE);

#pragma omp critical
        {
            printf( buffer );
        }
    }

    return;
}
