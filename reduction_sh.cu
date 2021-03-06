

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <float.h>

#include <cutil_inline.h>

////////////////////////////////////////////////////////////////////////////////
// CPU routines
////////////////////////////////////////////////////////////////////////////////


void reduction_gold(float* odata, float* idata, const unsigned int len) 
{
  *odata = 0;
  for(int i=0; i<len; i++) *odata += idata[i];
}


////////////////////////////////////////////////////////////////////////////////
// GPU routines
////////////////////////////////////////////////////////////////////////////////

__global__ void reduction_shared(float *g_odata, float *g_idata)
{
    extern __shared__ float temp[];
    int tid = threadIdx.x;

    // first, each thread loads data into shared memory

    temp[tid] = g_idata[tid];

    // next, we perform binary tree reduction

    for (int d = blockDim.x>>1; d > 0; d >>= 1) {
        __syncthreads();
      if (tid<d)  temp[tid] += temp[tid+d];

    }

    // finally, first thread puts result into global memory

    if (tid==0) g_odata[0] = temp[0];
}

__global__ void reduction_dev(float *g_odata, float *g_idata, float *scratch)
{
    int tid = threadIdx.x;

    // first, each thread loads data into shared memory

    scratch[tid] = g_idata[tid];

    // next, we perform binary tree reduction

    for (int d = blockDim.x>>1; d > 0; d >>= 1) {
        __syncthreads();
      if (tid<d)  scratch[tid] += scratch[tid+d];
    }

    // finally, first thread puts result into global memory

    if (tid==0) g_odata[0] = scratch[0];
}



////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////

int main( int argc, char** argv) 
{
  int num_elements, num_threads, mem_size, shared_mem_size;
  double timer, elapsed_dev, elapsed_share;
  float *h_data, *reference, sum, h_out=0;
  float *d_idata, *d_odata, *d_scratch;

  cutilDeviceInit(argc, argv);

  num_elements = 1024;
  num_threads  = num_elements;
  mem_size     = sizeof(float) * num_elements;

  // allocate host memory to store the input data
  // and initialize to integer values between 0 and 1000

  h_data = (float*) malloc(mem_size);
      
  for(int i = 0; i < num_elements; i++) 
    h_data[i] = floorf(1000*(rand()/(float)RAND_MAX));

  // compute reference solutions

  reference = (float*) malloc(mem_size);
  reduction_gold(&sum, h_data, num_elements);

  // allocate device memory input and output arrays

  cudaSafeCall(cudaMalloc((void**)&d_idata, mem_size));
  cudaSafeCall(cudaMalloc((void**)&d_odata, sizeof(float)));
  cudaSafeCall(cudaMalloc((void**)&d_scratch, mem_size));
  cudaSafeCall(cudaMemcpy(d_idata, h_data, mem_size, cudaMemcpyHostToDevice));



  // execute the kernel
  shared_mem_size = sizeof(float) * num_elements;
	  reduction_shared<<<1,num_threads,shared_mem_size>>>(d_odata,d_idata);
  cudaCheckMsg("reduction kernel execution failed");
  //for (int i = 0; i < 1000; ++i) 
  elapsed_time(&timer);
	  reduction_shared<<<1,num_threads,shared_mem_size>>>(d_odata,d_idata);
	  //reduction_shared<<<1,num_threads,shared_mem_size>>>(d_odata,d_idata);
  cudaCheckMsg("reduction kernel execution failed");
  cudaSafeCall(cudaDeviceSynchronize());
  elapsed_share = elapsed_time( &timer );
  printf("\n Shared memory took %13.8f \n", elapsed_share);
  cudaSafeCall(cudaMemcpy(&h_out, d_odata, sizeof(float),
                           cudaMemcpyDeviceToHost));

  // check results

  printf("Shmem reduction error = %f\n",h_out-sum);


  //print timing difference


  // cleanup memory

  free(h_data);
  free(reference);
  cudaSafeCall(cudaFree(d_idata));
  cudaSafeCall(cudaFree(d_odata));
  cudaSafeCall(cudaFree(d_scratch));

  // CUDA exit -- needed to flush printf write buffer

  cudaDeviceReset();
}
