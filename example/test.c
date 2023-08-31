#include<stdio.h>
#include<stdlib.h>

#ifdef OMP
#include<omp.h>
#endif

#ifdef PAPI
#include<papi.h>
#endif

#define N 1000000000

unsigned long omp_get_thread_num_wrapper(void){
    return (unsigned long)omp_get_thread_num();
}

// see src/ctests/zero_omp.c for comparison

// https://bitbucket.org/icl/papi/wiki/PAPI-Parallel-Programs
// https://bitbucket.org/icl/papi/wiki/Downloading-and-Installing-PAPI
int main(int argc, char **argv)
{
  int retval;
  int i,n,nt,tid;
  double a[N], b[N], sum=0.0;
  double ts, tf;
  
#ifdef OMP
  nt = atoi(argv[1]);
  omp_set_num_threads(nt);
#ifdef PAPI
  retval = PAPI_library_init( PAPI_VER_CURRENT );
  if ( retval != PAPI_VER_CURRENT ) {
    printf("error in PAPI_library_init()\n");
    exit(1);
  } 
  if (PAPI_thread_init( omp_get_thread_num_wrapper ) != PAPI_OK) {
    printf("error in PAPI_thread_init()\n");
    exit(1);
  }
#endif
#endif
  for (i=0;i<N;++i){
    a[i] = 1;
    b[i] = -1;
  }

#ifdef OMP
  ts = omp_get_wtime();
#endif


#pragma omp parallel private(tid)
  {
    tid = omp_get_thread_num_wrapper();
    printf("tid = %d\n",tid);
  }

// https://groups.google.com/a/icl.utk.edu/g/ptools-perfapi/c/O6KDx_IcPOM/m/YSNFqfnuCQAJ
  
#pragma omp parallel shared(n,a,b) private(i) reduction(+:sum) 
  {
#ifdef PAPI
    PAPI_hl_region_begin("dotp");
#endif
    
#pragma omp for 
    for (i=0;i<N;++i){
      sum += a[i]*b[i];
    }
#ifdef PAPI
    PAPI_hl_region_end("dotp");
#endif
  }
#ifdef OMP
  tf = omp_get_wtime();
#endif
printf("dot product:%f,  time(s)%f\n", sum,(tf-ts));
}


