```
salloc --nodes=2 --reservation=nvshmem_xp --time=1-0 --gpus=16 bash
# ip-26-0-164-[45,75]

uv venv env_nvshmem --python 3.12
source env_nvshmem/bin/activate
source debug/env && uv pip install -e . 2>&1 | tee log.txt
uv pip install numpy
uv pip uninstall nvidia-nvshmem-cu12 # So that it relies on our nvshmem installation and not the bundled one
```