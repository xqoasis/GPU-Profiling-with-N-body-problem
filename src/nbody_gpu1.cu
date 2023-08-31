#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include<omp.h>
#include "timer.h"
#include <papi.h>

#define BLOCK_SIZE 128
#define SOFTENING 1e-9f

typedef struct { float x, y, z, vx, vy, vz; } Body;
struct timeval timerStart;

void StartTimer(){
  gettimeofday(&timerStart, NULL);
}

double GetTimer(){
  struct timeval timerStop, timerElapsed;
  gettimeofday(&timerStop, NULL);
  timersub(&timerStop, &timerStart, &timerElapsed);

  return timerElapsed.tv_sec*1000.0+timerElapsed.tv_usec/1000.0;
    
}

/*
  initialize in memory as as:
  (particle 0:) x0 y0 z0 0.0 0.0 0.0
  (particle 1:) x1 y1 z1 0.0 0.0 0.0
  ....
*/
void randomizeBodies(float *data, int n) {
  for (int i = 0; i < n; i+=6){
      for (int j=0;j<=2;++j){	
        data[i+j] = 2.0f * (rand() / (float)RAND_MAX) - 1.0f;
	data[i+j+3]=0;
      }
  }
}

__global__ void bodyForce(Body *p, float dt, int n) {
  int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < n) {
    float Fx = 0.0f; float Fy = 0.0f; float Fz = 0.0f;

    for (int j = 0; j < n; j++) {
      float dx = p[j].x - p[i].x;   /* p[i].x and p[j].x are generally far apart in memory */
      float dy = p[j].y - p[i].y;
      float dz = p[j].z - p[i].z;
      float distSqr = dx*dx + dy*dy + dz*dz + SOFTENING;
      float invDist = rsqrtf(distSqr);
      float invDist3 = invDist * invDist * invDist;

      Fx += dx * invDist3; Fy += dy * invDist3; Fz += dz * invDist3;
    }

    p[i].vx += dt*Fx; p[i].vy += dt*Fy; p[i].vz += dt*Fz;
  }
}

void handle_error (int retval){
	printf("PAPI error %d: %s\n", retval, PAPI_strerror(retval));
	exit(1);
}

double my_timer(void){
  struct timeval time;
  gettimeofday(&time, 0);
  return time.tv_sec + time.tv_usec/1000000.0;
}

int main(const int argc, const char** argv) {
  FILE* datafile = NULL;  
  int nBodies;
  int nIters;
  int nt;
  nBodies = atoi(argv[1]);
  nIters  = atoi(argv[2]);
  nt      = atoi(argv[3]);
  const float dt = 0.01f; // time step

  int bytes = nBodies*sizeof(Body);
  float *buf = (float*)malloc(bytes);
  Body *p = (Body*)buf;

  omp_set_num_threads(nt);
  srand(100);
  randomizeBodies(buf, 6*nBodies); // Init pos / vel data

  float *d_buf;
  cudaMalloc(&d_buf, bytes);
  Body *d_p = (Body*)d_buf;

  int nBlocks = (nBodies + BLOCK_SIZE - 1) / BLOCK_SIZE;
  double totalTime = 0.0; 
  double totalBodyForceTime = 0.0;
  double totalBodyFracForceTime = 0.0;
  int ret;
  double ts, tf, body_ts, body_tf;

  datafile = fopen("nbody.dat","w");  /* open output file */
//  fprintf(datafile,"%d %d %d\n", nBodies, nIters, 0);


  for (int iter = 1; iter <= nIters; iter++) {
    printf("iteration:%d\n", iter);

//    for (int i=0;i<nBodies;++i)
//      fprintf(datafile, "%f %f %f \n", p[i].x, p[i].y, p[i].z);

    StartTimer();

    ts = GetTimer(); 
    cudaMemcpy(d_buf, buf, bytes, cudaMemcpyHostToDevice);//copy data to GPU
    body_ts = GetTimer();
    bodyForce<<<nBlocks, BLOCK_SIZE>>>(d_p, dt, nBodies); // compute interbody forces
    body_tf = GetTimer();
    cudaMemcpy(buf, d_buf, bytes, cudaMemcpyDeviceToHost);//copy data back to CPU
    tf = GetTimer();

    #pragma omp parallel for 
    for (int i = 0 ; i < nBodies; i++) { // integrate positions forward
      p[i].x += p[i].vx*dt;
      p[i].y += p[i].vy*dt;
      p[i].z += p[i].vz*dt;
    }

    const double tElapsed = GetTimer() / 1000.0;
    if (iter > 1) { // First iter is warm up
      totalTime += tElapsed; 
      totalBodyForceTime += tf - ts;
      totalBodyFracForceTime += body_tf - body_ts;
    }
    if (iter == 1) {                      
      // First iter is warm up, then start papi
      ret = PAPI_hl_region_begin("gpu1");
      if (ret != PAPI_OK) {
		    handle_error(1);
	    }
    }
  }
  ret = PAPI_hl_region_end("gpu1");
  if (ret != PAPI_OK) {
		handle_error(1);
	}
  fclose(datafile);
  double avgTime = totalTime / (double)(nIters-1); 
  double avgBodyForceTime = totalBodyForceTime / (double)(nIters-1); 
  double avgBodyFracForceTime = totalBodyFracForceTime / (double)(nIters-1);

  printf("avgTime: %f   totTime: %f \n", avgTime, totalTime);
  printf("avgBodyForceTime: %f   totBodyForceTime: %f \n", avgBodyForceTime, totalBodyForceTime);
  printf("avgBodyFracForceTime: %f   totBodyFracForceTime: %f \n", avgBodyFracForceTime, totalBodyFracForceTime);

  free(buf);
  cudaFree(d_buf);
}
