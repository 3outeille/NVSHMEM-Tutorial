#include <stdio.h>
#include <cuda.h>
#include <nvshmem.h>
#include <nvshmemx.h>

__global__ void simple_shift(int *destination) {
    int mype = nvshmem_my_pe();
    int npes = nvshmem_n_pes();

    //printf("PMI_RANK=%d, PMI_SIZE=%d\n", mype, npes);

    int peer = (mype + 1) % npes;

    nvshmem_int_p(destination, mype, peer);
}

int main(void) {
    printf("STARTING CUDA hello ...\n");
    
    int mype_node, msg;
    cudaStream_t stream;

    printf("nvshmem_init start ...\n");
    //setenv("NVSHMEM_SYMMETRIC_SIZE", "1073741824", 1);  // 1GB heap
    nvshmem_init();
    nvshmem_barrier_all();  // ensure all PEs finished init
    printf("nvshmem_init Done\n");

    int mype = nvshmem_my_pe();
    int npes = nvshmem_n_pes();
    printf("PMI_RANK=%d, PMI_SIZE=%d\n", mype, npes);

    printf("nvshmem_team_my_pe start ...\n");
    mype_node = nvshmem_team_my_pe(NVSHMEMX_TEAM_NODE);
    printf("nvshmem_team_my_pe Done\n");
    printf("cudaSetDevice, cudaStreamCreate start ...\n");
    cudaSetDevice(mype_node);
    cudaStreamCreate(&stream);
    printf("cudaSetDevice, cudaStreamCreate done\n");

    printf("nvshmem_malloc start ...\n");
    int *destination = (int *) nvshmem_malloc(sizeof(int));
    printf("nvshmem_malloc done\n");

    simple_shift<<<1, 1, 0, stream>>>(destination);
    nvshmemx_barrier_all_on_stream(stream);
    cudaMemcpyAsync(&msg, destination, sizeof(int), cudaMemcpyDeviceToHost, stream);

    cudaStreamSynchronize(stream);
    printf("%d: received message %d\n", nvshmem_my_pe(), msg);

    nvshmem_free(destination);
    nvshmem_finalize();
    return 0;
}
