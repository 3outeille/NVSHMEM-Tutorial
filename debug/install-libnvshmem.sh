#!/usr/bin/env bash
set -euxo pipefail

module unload cuda/12.9
module unload cuda/12.4
module load cuda/12.9

source ./env

unset NVSHMEM_HOME

NVSHMEM_VERSION="${NVSHMEM_VERSION:-3.4.5}"
CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
LIBFABRIC_HOME="${LIBFABRIC_HOME:-/opt/amazon/efa}"
MPI_HOME="${MPI_HOME:-/opt/amazon/openmpi}"
TMP_DIR="${TMP_DIR:-/tmp}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/nvshmem-$NVSHMEM_VERSION}"

SRC_TAR="${NVSHMEM_SRC_TAR:-nvshmem_src_cuda-all-all-3.4.5.tar.gz}"
SRC_URL="${NVSHMEM_SRC_URL:-https://github.com/NVIDIA/nvshmem/releases/download/v3.4.5-0/$SRC_TAR}"

if [ -d "$INSTALL_PREFIX" ]; then
  echo "NVSHMEM $NVSHMEM_VERSION already installed at $INSTALL_PREFIX"
  exit 0
fi

cd "$TMP_DIR"
[ -f "$SRC_TAR" ] || wget --tries=3 --timeout=30 -O "$SRC_TAR" "$SRC_URL"

STAGING_DIR="$TMP_DIR/nvshmem-build-$NVSHMEM_VERSION"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
tar xvf "$SRC_TAR" -C "$STAGING_DIR"

SRC_DIR="$STAGING_DIR/nvshmem_src"
BUILD_DIR="$SRC_DIR/build"

cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
  -DNVSHMEM_LIBFABRIC_SUPPORT=ON \
  -DNVSHMEM_MPI_SUPPORT=ON \
  -DNVSHMEM_SHMEM_SUPPORT=OFF \
  -DLIBFABRIC_HOME="$LIBFABRIC_HOME" \
  -DFABRIC_INCLUDE_DIR="$LIBFABRIC_HOME/include" \
  -DFABRIC_LIBRARIES="$LIBFABRIC_HOME/lib/libfabric.so" \
  -DMPI_C_COMPILER="$MPI_HOME/bin/mpicc" \
  -DMPI_CXX_COMPILER="$MPI_HOME/bin/mpicxx"

cmake --build "$BUILD_DIR" -j"$(nproc)"
cmake --install "$BUILD_DIR"

sudo mkdir -p "$INSTALL_PREFIX"
sudo rsync -a "$STAGING_DIR/" "$INSTALL_PREFIX/"

echo "Done. Set NVSHMEM_HOME=$INSTALL_PREFIX"