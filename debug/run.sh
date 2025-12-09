#!/usr/bin/env bash

# scontrol create reservation reservationName=nvshmem_xp nodeCnt=2 starttime=now duration="6-00:00:00" account=huggingface partition=hopper-prod flags=maint
# cd ~/fsx_mathieu_morlon/nvshmem-hello
# salloc --nodes=2 --reservation=nvshmem_xp --time=1-0 --exclusive bash


module unload cuda/12.9
module unload cuda/12.4
module load cuda/12.9

source ./env

nvcc --version

echo "\$NVSHMEM_LIBFABRIC_SUPPORT : $NVSHMEM_LIBFABRIC_SUPPORT"
echo "\$LIBFABRIC_HOME : $LIBFABRIC_HOME"
echo "\$FI_PROVIDER : $FI_PROVIDER"
echo "\$NVSHMEM_HOME : $NVSHMEM_HOME"
echo "\$LD_LIBRARY_PATH : $LD_LIBRARY_PATH"

echo -n "⚒️👷🏗️   Compiling my_nvshmem_hello.cu with nvcc and loading CUDA modules... "

nvcc -rdc=true -ccbin g++ -gencode=arch=compute_90,code=sm_90 \
  -I $NVSHMEM_HOME \
  my_nvshmem_hello.cu \
  /usr/lib/x86_64-linux-gnu/nvshmem/12/libnvshmem_device.a \
  -o nvshmem_hello \
  -L /usr/lib/x86_64-linux-gnu/nvshmem/ \
  -lnvshmem_host -lnvshmem_device && echo "✅ COMPILE OK" || echo "compile failure ‼  ️⚠️"

echo "🚀🏁▶️   Running nvshmem_hello via nvshmrun.hydra ..."
echo ""
set -o pipefail
set -x
#/usr/bin/nvshmem_12/nvshmrun.hydra -np 8 -gpus-per-proc 2 -prepend-rank -f hosts.txt bash -c "source ./env ; ./nvshmem_hello" 2>&1 | tee hello.log 
/usr/bin/nvshmem_12/nvshmrun.hydra -np 8 -gpus-per-proc 2 -prepend-rank -f hosts.txt ./nvshmem_hello 2>&1 | tee hello.log 
#/usr/bin/nvshmem_12/nvshmrun.hydra -np 8 -gpus-per-proc 1 -prepend-rank -f hosts_single.txt bash -c "source ./env ; ./nvshmem_hello" 2>&1 | tee hello.log 
return_code=$?
set +x

if [ $return_code -eq 0 ]; then
    echo "✅✌️ nvshmem_hello ran with success"
else
    echo " ⛔‼️ Failure of nvshmem_hello execution" 
fi

echo " 📝 For logs, run:"
echo "less hello.log"
