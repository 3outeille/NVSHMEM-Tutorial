# Installation

```
salloc --nodes=2 --reservation=nvshmem_xp --time=1-0 --gpus=16 bash
# ip-26-0-164-[45,75]

uv venv env_nvshmem --python 3.12
source env_nvshmem/bin/activate
source debug/env && uv pip install -e . 2>&1 | tee log.txt
uv pip install numpy
uv pip uninstall nvidia-nvshmem-cu12 # So that it relies on our nvshmem installation and not the bundled one
```

# Run

```
python -m torch.distributed.run --nproc_per_node=2 tests/test_intranode_nvshmem.py
```

```bash
(env_nvshmem) ➜  NVSHMEM-Tutorial git:(main) ✗ python -m torch.distributed.run --nproc_per_node=2 tests/test_intranode_nvshmem.py       

*****************************************
Setting OMP_NUM_THREADS environment variable for each process to be 1 in default, to avoid your system being overloaded, please further tune the variable for optimal performance in your application as needed. 
*****************************************
[Rank 1] Setting device to cuda:1
[Rank 0] Setting device to cuda:0
[Rank 0] NVSHMEM initialized successfully.[Rank 1] NVSHMEM initialized successfully.

/fsx/ferdinandmom/ferdinand-hf/NVSHMEM-Tutorial/env_nvshmem/lib/python3.12/site-packages/torch/distributed/distributed_c10d.py:4876: UserWarning: barrier(): using the device under current context. You can specify `device_id` in `init_process_group` to mute this warning.
  warnings.warn(  # warn only once
remote_tensor: tensor([1, 1, 1,  ..., 1, 1, 1], device='cuda:1', dtype=torch.uint8)
local_tensor: tensor([1, 1, 1,  ..., 1, 1, 1], device='cuda:1', dtype=torch.uint8)
libfabric:3205148:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205148:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205148:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205148:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205147:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205147:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205147:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
libfabric:3205147:1765657721::efa:fabric:efa_fabric_close():38<warn> Unable to close fabric: Device or resource busy
```