#!/usr/bin/env bash

set -e

# GPAW
# This location (my_prefix) is expected to hold the libxc installation

export my_prefix=$(pwd)
export libxc_prefix=${my_prefix}

module load PrgEnv-gnu
module load cray-python
module load cray-fftw

git clone -b 22.1.0 https://gitlab.com/gpaw/gpaw.git 
cd gpaw

cp ../siteconfig.py .
sed -i "s#LIBXC_PATH#${libxc_prefix}#" siteconfig.py

python setup.py build_ext
python setup.py install --prefix=${my_prefix}
