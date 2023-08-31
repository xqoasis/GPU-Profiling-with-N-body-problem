#!/bin/bash

module load papi
module load nvhpc
# papi_version
# papi_avail

## Other commands
# tcsh
# setenv PAPI_REPORT 1
# setenv PAPI_EVENTS "PAPI_L1_TCM, PAPI_LD_INS, PAPI_SR_INS, PAPI_L2_TCM, PAPI_L2_TCA, PAPI_L3_TCA, PAPI_L3_TCM"
# setenv PAPI_EVENTS "PAPI_SP_OPS, PAPI_DP_OPS, PAPI_TOT_CYC"
# setenv PAPI_EVENTS "PAPI_STL_CCY, PAPI_TLB_DM, PAPI_BR_MSP, PAPI_BR_INS, PAPI_RES_STL"

## Compile
gcc ./src/nbody_cpu_multicore.c ./src/timer.c -o nbody_cpu_multicore -fopenmp -O2 -lpapi -lm
gcc ./src/nbody_cpu_serial.c ./src/timer.c -o nbody_cpu_serial -fopenmp -O2 -lpapi -lm
nvc++ -o nbody_gpu1 ./src/nbody_gpu1.cu -fopenmp -lpapi -lm
nvc++ -o nbody_gpu2 ./src/nbody_gpu2.cu -fopenmp -lpapi -lm
nvc++ -o nbody_gpu3 ./src/nbody_gpu3.cu -fopenmp -lpapi -lm
nvc++ -o nbody_gpu4 ./src/nbody_gpu4.cu -fopenmp -lpapi -lm

# gcc test.c -o test -fopenmp -O2 -lpapi -lm