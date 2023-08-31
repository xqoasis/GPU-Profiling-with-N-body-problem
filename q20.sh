#!/bin/bash
./nbody_gpu1 1000 20 2 >> q16.txt
./nbody_gpu1 10000 20 2 >> q16.txt
./nbody_gpu1 100000 20 2 >> q16.txt
./nbody_gpu1 500000 20 2 >> q16.txt
./nbody_gpu2 1000 20 12 >> q16.txt
./nbody_gpu2 10000 20 12 >> q16.txt
./nbody_gpu2 100000 20 12 >> q16.txt
./nbody_gpu2 500000 20 12 >> q16.txt
./nbody_gpu3 1000 20 12 >> q16.txt
./nbody_gpu3 10000 20 12 >> q16.txt
./nbody_gpu3 100000 20 12 >> q16.txt
./nbody_gpu3 500000 20 12 >> q16.txt
./nbody_gpu4 1000 20 12 >> q16.txt
./nbody_gpu4 10000 20 12 >> q16.txt
./nbody_gpu4 100000 20 12 >> q16.txt
./nbody_gpu4 500000 20 12 >> q16.txt