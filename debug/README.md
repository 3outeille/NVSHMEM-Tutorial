```
salloc --nodes=2 --reservation=nvshmem_xp --time=1-0 --gpus=16 bash
# ip-26-0-164-[45,75]

# terminal 1
ssh ip-26-0-164-45
./debug/run.sh

# terminal 2
ssh ip-26-0-164-75 
./debug/run.sh
```