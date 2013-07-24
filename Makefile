
INC	:= -I$(CUDA_HOME)/include -I.
LIB	:= -L$(CUDA_HOME)/lib -lcudart

# NVCCFLAGS	:= -arch=sm_20 -DCUDA_DEVICE=0 --ptxas-options=-v --use_fast_math
NVCCFLAGS	:= -arch=sm_20 --ptxas-options=-v --use_fast_math -G -g

reduction:	reduction.cu reduction_dev.cu reduction_sh.cu
		nvcc reduction.cu -o reduction $(INC) $(NVCCFLAGS) $(LIB)
		nvcc reduction_dev.cu -o reduction_dev $(INC) $(NVCCFLAGS) $(LIB)
		nvcc reduction_sh.cu -o reduction_sh $(INC) $(NVCCFLAGS) $(LIB)

clean:
		rm -f reduction

