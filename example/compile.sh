#!/bin/csh
set echo on
# set EXE = $argv[1]

gcc -fopenmp -DOMP -DPAPI -O2 -I/usr/local/papi/6.0/include -c test2.c
gcc -fopenmp -DOMP -DPAPI -O2 -o test2 test2.o -L/usr/local/papi/6.0/lib -lpapi