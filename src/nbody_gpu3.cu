#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "timer.h"
#include <papi.h>

#define BLOCK_SIZE 256
#define SOFTENING 1e-9f

typedef struct { float4 *pos, *vel; } BodySystem;
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
void randomizeBodies(float *data, int n) {
  for (int i = 0; i < n; i++) {
    data[i] = 2.0f * (rand() / (float)RAND_MAX) - 1.0f;
  }
}

__global__
void bodyForce(float4 *p, float4 *v, float dt, int n) {
  int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < n) {
    float Fx = 0.0f; float Fy = 0.0f; float Fz = 0.0f;

    for (int tile = 0; tile < gridDim.x; tile++) {
      __shared__ float3 spos[BLOCK_SIZE];
      float4 tpos = p[tile * blockDim.x + threadIdx.x];
      spos[threadIdx.x] = make_float3(tpos.x, tpos.y, tpos.z);
      __syncthreads();

      for (int j = 0; j < BLOCK_SIZE; j++) {
        float dx = spos[j].x - p[i].x;
        float dy = spos[j].y - p[i].y;
        float dz = spos[j].z - p[i].z;
        float distSqr = dx*dx + dy*dy + dz*dz + SOFTENING;
        float invDist = rsqrtf(distSqr);
        float invDist3 = invDist * invDist * invDist;

        Fx += dx * invDist3; Fy += dy * invDist3; Fz += dz * invDist3;
      }
      __syncthreads();
    }

    v[i].x += dt*Fx; v[i].y += dt*Fy; v[i].z += dt*Fz;
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
  
  int nBodies = 100000;
  if (argc > 1) nBodies = atoi(argv[1]);
  
  const float dt = 0.01f; // time step
  const int nIters = 20;  // simulation iterations
  
  int bytes = 2*nBodies*sizeof(float4);
  float *buf = (float*)malloc(bytes);
  BodySystem p = { (float4*)buf, ((float4*)buf) + nBodies };

  randomizeBodies(buf, 8*nBodies); // Init pos / vel data

  float *d_buf;
  cudaMalloc(&d_buf, bytes);
  BodySystem d_p = { (float4*)d_buf, ((float4*)d_buf) + nBodies };

  int nBlocks = (nBodies + BLOCK_SIZE - 1) / BLOCK_SIZE;
  double totalTime = 0.0; 
  double totalBodyForceTime = 0.0;
  double totalBodyFracForceTime = 0.0;
  int ret;
  double ts, tf, body_ts, body_tf;

  for (int iter = 1; iter <= nIters; iter++) {
    printf("iteration:%d\n", iter);  	     
    StartTimer();

    ts = GetTimer();
    cudaMemcpy(d_buf, buf, bytes, cudaMemcpyHostToDevice);
    body_ts = GetTimer();
    bodyForce<<<nBlocks, BLOCK_SIZE>>>(d_p.pos, d_p.vel, dt, nBodies);
    body_tf = GetTimer();
    cudaMemcpy(buf, d_buf, bytes, cudaMemcpyDeviceToHost);
    tf = GetTimer();

    for (int i = 0 ; i < nBodies; i++) { // integrate position
      p.pos[i].x += p.vel[i].x*dt;
      p.pos[i].y += p.vel[i].y*dt;
      p.pos[i].z += p.vel[i].z*dt;
    }

    const double tElapsed = GetTimer() / 1000.0;
    if (iter > 1) { // First iter is warm up
      totalTime += tElapsed; 
      totalBodyForceTime += tf - ts;
      totalBodyFracForceTime += body_tf - body_ts;
    }
    if (iter == 2) {                      
      // First iter is warm up, then start papi
      ret = PAPI_hl_region_begin("gpu3");
      if (ret != PAPI_OK) {
		    handle_error(1);
	    }
    }

  }
  ret = PAPI_hl_region_end("gpu3");
  if (ret != PAPI_OK) {
		handle_error(1);
	}
  double avgTime = totalTime / (double)(nIters-1); 
  double avgBodyForceTime = totalBodyForceTime / (double)(nIters-1); 
  double avgBodyFracForceTime = totalBodyFracForceTime / (double)(nIters-1); 
  printf("avgTime: %f   totTime: %f \n", avgTime, totalTime);
  printf("avgBodyForceTime: %f   totBodyForceTime: %f \n", avgBodyForceTime, totalBodyForceTime);
  printf("avgBodyFracForceTime: %f   totBodyFracForceTime: %f \n", avgBodyFracForceTime, totalBodyFracForceTime);

  free(buf);
  cudaFree(d_buf);
}
