/* Simple code to test PAPI with threading */
#include "omp.h"
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <time.h>
#include <assert.h>
// This include path is for MCS machines
#include "papi.h"

int handleError(int retval) {

    int tid = omp_get_thread_num();
    if( retval == PAPI_OK )
        return retval;

    printf("%s: TID %d\n", PAPI_strerror(retval), tid);
    return retval;
}

int main(int argc, char **argv){

    int i,j;
    int retval;
    int Events[] = {PAPI_L2_TCA};
    char eventname[256];

    if( argc != 4 ){
        printf("Enter num_threads, length of arrays, event to count\n");
        exit(1);
    }

    float *a, *b, *c;

    int *EventSets;
    long long **vals;
    size_t num_events = sizeof(Events)/sizeof(int);    

    int num_threads = atoi(argv[1]);
    int length = atoi(argv[2]);

    /***************************************/
    retval = PAPI_library_init(PAPI_VER_CURRENT);
    assert( retval == PAPI_VER_CURRENT );

    retval = PAPI_thread_init( pthread_self );
    assert( retval == PAPI_OK );
    /***************************************/
    handleError( PAPI_event_name_to_code(argv[3],&Events[0]));

    /* Test array setup    */
    /**************************************/
    a = (float *) malloc ( length * sizeof(float));
    b = (float *) malloc ( length * sizeof(float));
    c = (float *) malloc ( length * sizeof(float));

    for(i=0; i<length; i++){
        a[i] = (float) i;
        b[i] = (float) rand() / RAND_MAX; 
        c[i] = 0.0;
    }
    /**************************************/

    /***************************************/
    vals = (long long **) malloc( num_threads * sizeof(long long *));
    for(i=0; i<num_threads; i++){
        vals[i] = (long long *) malloc( num_events * sizeof(long long));
        for(j=0; j<num_events; j++){
            vals[i][j] = 0;
        }
    }
    /***************************************/

    long long e, s; // Timing counters in # usecs
    double tf, ts;
    omp_set_num_threads(num_threads);

    ts = omp_get_wtime();
#pragma omp parallel private(retval) shared(num_events)
   {
        int tid = omp_get_thread_num();  
        long long *myvals = vals[tid];
        long long count = 0;
        int EventSet = PAPI_NULL; // EventSet must be initialized to PAPI_NULL

        retval = PAPI_create_eventset(&EventSet);
        PAPI_add_events(EventSet,Events,num_events);
        handleError( PAPI_start(EventSet) );
        handleError( PAPI_reset(EventSet) );
#pragma omp for schedule(static) nowait
        for(i=0; i<length; ++i){
            c[i] = a[i] + b[i];
        }
        handleError( PAPI_accum(EventSet,&count));
        handleError( PAPI_stop(EventSet,NULL));
        handleError( PAPI_cleanup_eventset(EventSet));
        PAPI_event_code_to_name(Events[0],eventname);
        printf("tid:%d %s: %lld\n", tid, eventname, count);
   }
    tf = omp_get_wtime();
    printf("time:%f(s)\n", tf-ts);

    free(a);
    free(b);
    free(c);

    return 0;
}
