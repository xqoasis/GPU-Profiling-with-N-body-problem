#!/bin/bash
./nbody_cpu_multicore 100000 2 >> q16.txt
./nbody_cpu_multicore 100000 4 >> q16.txt
./nbody_cpu_multicore 100000 8 >> q16.txt
./nbody_cpu_multicore 100000 16 >> q16.txt
./nbody_cpu_multicore 100000 32 >> q16.txt
./nbody_cpu_multicore 100000 48 >> q16.txt
./nbody_cpu_multicore 100000 64 >> q16.txt

./nbody_cpu_multicore 5000 1 >> q16_2.txt
./nbody_cpu_multicore 10000 2 >> q16_2.txt
./nbody_cpu_multicore 20000 4 >> q16_2.txt
./nbody_cpu_multicore 40000 8 >> q16_2.txt
./nbody_cpu_multicore 80000 16 >> q16_2.txt
./nbody_cpu_multicore 160000 32 >> q16_2.txt
./nbody_cpu_multicore 240000 48 >> q16_2.txt
./nbody_cpu_multicore 320000 64 >> q16_2.txt