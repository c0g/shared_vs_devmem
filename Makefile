
INC	:= -I$(CUDA_HOME)/include -I.
LIB	:= -L$(CUDA_HOME)/lib -lcudart

# NVCCFLAGS	:= -arch=sm_20 -DCUDA_DEVICE=0 --ptxas-options=-v --use_fast_math
NVCCFLAGS	:= -arch=sm_20 --ptxas-options=-v --use_fast_math

reduction:	reduction.cu
		nvcc reduction.cu -o reduction $(INC) $(NVCCFLAGS) $(LIB)

clean:
		rm -f reduction

