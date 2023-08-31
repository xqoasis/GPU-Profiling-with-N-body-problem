#!/bin/bash
module load intel
icc -O2 -qopenmp ./src/nbody_cpu_multicore.c ./src/timer.c -o nbody_cpu_multicore_intel -lpapi -lm -qopt-report-phase=vec -qopt-report=1
icc -O2 -qopenmp ./src/nbody_cpu_multicore.c ./src/timer.c -o nbody_cpu_multicore_intel_no -lpapi -lm -qopt-report-phase=vec -qopt-report=1 -no-vec
icc -O2 -qopenmp ./src/nbody_cpu_serial.c ./src/timer.c -o nbody_cpu_serial_intel -lpapi -lm -qopt-report-phase=vec -qopt-report=1