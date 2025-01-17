Instructions for building Horovod for the Cirrus GPU nodes
==========================================================

These instructions show how to build a Python virtual environment (venv) that provides Horovod 0.24.2, a distributed deep learning training framework,
one that encompasses TensorFlow 2.8.0 (https://www.tensorflow.org/), PyTorch 1.11.0 (https://pytorch.org/) and MXNet 1.9.0 (https://mxnet.apache.org/).

The Horovod environment is intended to run on the Cirrus GPU nodes (Cascade Lake, NVIDIA Tesla V100-SXM2-16GB).

This venv is an extension of the Miniconda3 (Python 3.8.12) environment provided by the `mpi4py/3.1.3-ompi-gpu` module.
MPI comms is handled by the [Horovod](https://horovod.readthedocs.io/en/stable/index.html) 0.24.2 package (built with NCCL 2.11.4).
Horovod is required for running TensorFlow/PyTorch over multiple GPUs distributed across multiple compute nodes.


Setup initial environment
-------------------------

```bash
PRFX=/path/to/work  # e.g., PRFX=/mnt/lustre/indy2lfs/sw/miniconda3
cd ${PRFX}

TENSORFLOW_VERSION=2.8.0
PYTORCH_VERSION=1.11.0
MXNET_VERSION=1.9.0

HOROVOD_LABEL=horovod
HOROVOD_VERSION=0.24.2
HOROVOD_ROOT=${PRFX}/${HOROVOD_LABEL}

module load mpi4py/3.1.3-ompi-gpu

PYTHON_VER=`echo ${MINICONDA3_PYTHON_VERSION} | cut -d'.' -f1-2`
PYTHON_DIR=${PRFX}/${HOROVOD_LABEL}/${HOROVOD_VERSION}-gpu/python
PYTHON_BIN=${PYTHON_DIR}/${MINICONDA3_PYTHON_VERSION}/bin


mkdir -p ${PYTHON_BIN}

export PIP_CACHE_DIR=${PYTHON_DIR}/.cache/pip

export PYTHONUSERBASE=${PYTHON_DIR}/${MINICONDA3_PYTHON_VERSION}
export PATH=${PYTHONUSERBASE}/bin:${PATH}
export PYTHONPATH=${PYTHONUSERBASE}/lib/python${PYTHON_VER}/site-packages:${PYTHONPATH}
```

Remember to change the setting for `PRFX` to a path appropriate for your Cirrus project.


Install the machine learning packages
-------------------------------------

```bash
pip install --user pyspark
pip install --user scikit-learn
pip install --user scikit-image

pip install --user tensorflow
pip install --user tensorflow-gpu

pip install --user tensorflow-gpu==${TENSORFLOW_VERSION} \
                   tensorflow==${TENSORFLOW_VERSION}

pip install --user torch
pip install --user torchvision
pip install --user pytorch-lightning
pip install --user pytorch-lightning-bolts
pip install --user pytorch-lightning-bolts["extra"]
pip install --user lightning-flash
pip install --user 'lightning-flash[all]'

pip install --user torchaudio==0.11.0 \
                   torchvision==0.12.0 \
                   torch==${PYTORCH_VERSION}

pip install --user mxnet
pip install --user mxnet-cu112

pip install --user mxnet-cu112==${MXNET_VERSION} \
                   mxnet==${MXNET_VERSION}

pip install --user fastai
pip install --user opencv-python
```


Install Horovod linking with the Nvidia Collective Communications Library (NCCL)
--------------------------------------------------------------------------------

Please note, in preparation for the Horovod install, you must check that `libcuda.so.1`
exists as soft link to `libcuda.so` in `${NVHPC_ROOT}/cuda/lib64/stubs`.

```bash
module load cmake

# switch from nvidia to openmpi compilers
CC_SAVE=${CC}
CXX_SAVE=${CXX}
FC_SAVE=${FC}
export CC=mpicc
export CXX=mpicxx
export FC=mpifort

export LD_LIBRARY_PATH=${PRFX}/../nvidia/hpcsdk-222/Linux_x86_64/22.2/cuda/lib64/stubs:${LD_LIBRARY_PATH}

HOROVOD_CUDA_HOME=${NVHPC_ROOT}/cuda/11.6 HOROVOD_NCCL_HOME=${NVHPC_ROOT}/comm_libs/nccl \
HOROVOD_GPU=CUDA HOROVOD_BUILD_CUDA_CC_LIST=70 \
HOROVOD_CPU_OPERATIONS=MPI HOROVOD_GPU_OPERATIONS=NCCL \
HOROVOD_WITH_MPI=1 HOROVOD_WITH_TENSORFLOW=1 \
HOROVOD_WITH_PYTORCH=1 HOROVOD_WITH_MXNET=1 \
CUDA_PATH=${NVHPC_ROOT}/cuda/11.6 \    
pip install --user --no-cache-dir horovod[tensorflow,pytorch,mxnet]==${HOROVOD_VERSION}

# downgrade pytorch-lightning from 1.3.8 to 1.3.6 so that it is compatible with pytorch-tabular 0.7.0
pip install --user pytorch-lightning==1.3.6

export CC=${CC_SAVE}
export CXX=${CXX_SAVE}
export FC=${FC_SAVE}
```

Now run `horovodrun --check-build` to confirm that [Horovod](https://horovod.readthedocs.io/en/stable/index.html) has been installed
correctly. That command should return something like the following output

```
Horovod v0.24.2:

Available Frameworks:
    [X] TensorFlow
    [X] PyTorch
    [X] MXNet

Available Controllers:
    [X] MPI
    [X] Gloo

Available Tensor Operations:
    [X] NCCL
    [ ] DDL
    [ ] CCL
    [X] MPI
    [X] Gloo 
```