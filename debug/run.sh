#!/usr/bin/env bash

module unload cuda/12.9
module unload cuda/12.4
module load cuda/12.9

source ./env

#srun --mpi=pmix -l --reservation nvshmem_xp --gpus-per-task=1 --time 10 --nodes=2 --tasks-per-node=1 --ntasks 2 /usr/local/nvshmem-linux-3.4.5/bin/perftest/device/pt-to-pt/shmem_put_bw

echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

nvcc --version

echo "\$NVSHMEM_BOOTSTRAP : $NVSHMEM_BOOTSTRAP"

set -o pipefail
echo -n "⚒️👷🏗️   Compiling... "

nvcc -rdc=true -ccbin g++ -gencode=arch=compute_90,code=sm_90 \
  -I $NVSHMEM_HOME/include \
  my_nvshmem_hello.cu \
  -o nvshmem_hello \
  -L $NVSHMEM_HOME/lib \
  -lnvshmem

if [ $? -eq 0 ]; then
  echo "✅ COMPILE OK"
else
  echo "compile failure ‼️⚠️"
  exit 1
fi

echo "🚀 Testing with SINGLE NODE first (8 GPUs)..."

# Test with single node first
#-x MPI_HOME \
set -x
mpirun --hostfile hosts_single.txt -np 8 --map-by ppr:8:node \
  -x NVSHMEM_LIBFABRIC_SUPPORT \
  -x NVSHMEM_BOOTSTRAP \
  -x LD_LIBRARY_PATH \
  -x FI_PROVIDER \
  -x NVSHMEM_REMOTE_TRANSPORT \
  -x FI_EFA_USE_DEVICE_RDMA \
  -x NVSHMEM_LIBFABRIC_PROVIDER \
  -x FI_LOG_LEVEL \
  -x PATH \
  bash -c 'export CUDA_VISIBLE_DEVICES=${OMPI_COMM_WORLD_LOCAL_RANK}; echo "[Rank $OMPI_COMM_WORLD_RANK] CVD=$CUDA_VISIBLE_DEVICES"; exec ./nvshmem_hello' \
  2>&1 | tee hello.log

return_code=$?
set +x

if [ $return_code -eq 0 ]; then
    echo "✅ Single node SUCCESS! Now testing 2 nodes..."
else
    echo "⛔ Single node FAILED - fix this first before trying 2 nodes" 
    exit 1
fi

set -x
mpirun --hostfile hosts.txt -np 16 --map-by ppr:8:node \
  -x NVSHMEM_LIBFABRIC_SUPPORT \
  -x NVSHMEM_BOOTSTRAP \
  -x LD_LIBRARY_PATH \
  -x FI_PROVIDER \
  -x FI_EFA_USE_DEVICE_RDMA \
  -x NVSHMEM_LIBFABRIC_PROVIDER \
  -x FI_LOG_LEVEL \
  -x NVSHMEM_REMOTE_TRANSPORT \
  -x PATH \
  bash -c 'export CUDA_VISIBLE_DEVICES=${OMPI_COMM_WORLD_LOCAL_RANK}; echo "[Rank $OMPI_COMM_WORLD_RANK] CVD=$CUDA_VISIBLE_DEVICES"; exec ./nvshmem_hello' \
  2>&1 | tee hello_2node.log


  return_code=$?
set +x

if [ $return_code -eq 0 ]; then
    echo "✅ 2 nodes SUCCESS! "
else
    echo "⛔ 2 nodes FAILED" 
    exit 1
fi
