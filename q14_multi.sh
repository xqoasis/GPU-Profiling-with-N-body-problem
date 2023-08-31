#!/bin/bash
./nbody_cpu_multicore 100000 4 >> q14.txt
./nbody_cpu_multicore 100000 8 >> q14.txt
./nbody_cpu_multicore 100000 16 >> q14.txt
./nbody_cpu_multicore 100000 32 >> q14.txt