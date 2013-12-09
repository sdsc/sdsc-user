#define _GNU_SOURCE

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sched.h>

void print_cpuset( char *buffer, size_t string_size, cpu_set_t *cpuset );

#define STRING_SIZE 1024
int main ( int argc, char** argv )
{
    int mpi_rank, mpi_size;
    char host[STRING_SIZE];

    MPI_Init( &argc, &argv );
    MPI_Comm_rank( MPI_COMM_WORLD, &mpi_rank );
    MPI_Comm_size( MPI_COMM_WORLD, &mpi_size );

    gethostname( host, STRING_SIZE );
#if defined(_OPENMP) 
    #pragma omp parallel
    {
        char buffer[STRING_SIZE];
        char mybuf[STRING_SIZE] = "";
        cpu_set_t my_cpuset;

        sched_getaffinity(0, sizeof(cpu_set_t), &my_cpuset);

        snprintf( buffer, STRING_SIZE, 
            "Hello from thread %2d of %2d in rank %3d of %3d running on cpu %2d[",
            omp_get_thread_num(), 
            omp_get_num_threads(),
            mpi_rank, 
            mpi_size, 
            sched_getcpu() );

        print_cpuset( buffer, STRING_SIZE, &my_cpuset ),

        snprintf(mybuf, STRING_SIZE,  "] on %s\n", host );
        strncat(buffer, mybuf, STRING_SIZE);

#pragma omp critical
        {
            printf( buffer );
        }
    }
#else
    printf( "Hello from rank %d of %d running on cpu %d on %s\n", 
        mpi_rank, 
        mpi_size, 
        sched_getcpu(),
        host );
#endif

    MPI_Finalize();
    return 0;
}

void print_cpuset( char *buffer, size_t string_size, cpu_set_t *cpuset )
{
    int i, count;

    if ( !cpuset ) 
    {
        strncat( buffer, "ERR:null cpuset", STRING_SIZE );
        return;
    }

    for (i = 0, count = 0; i < CPU_SETSIZE; i++ )
    {
        if ( CPU_ISSET ( i, cpuset ) )
        {
            char mybuf[STRING_SIZE];
            *mybuf = '\0';
            if ( count++ > 0 ) strncat(buffer, ",", STRING_SIZE );
            snprintf( mybuf, STRING_SIZE, "%d", i );
            strncat(buffer, mybuf, STRING_SIZE );
        }
    }
    return;
}
