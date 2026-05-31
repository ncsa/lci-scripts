#%Module1.0
##
## TensorFlow 2.3.0 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads TensorFlow 2.3.0 with its dependencies."
}

module-whatis "Loads TensorFlow 2.3.0 environment"

# Load the dependencies or prerequisite modules if necessary
module load python/3.8
module load gcc/9.3.0
module load cuda/10.1
module load cudnn/7.6

# TensorFlow's own install tree
set root /opt/tensorflow/2.3.0

# PYTHONPATH: the python/3.8 site-packages directory where TensorFlow was pip-installed
prepend-path PYTHONPATH /opt/python/3.8/lib/python3.8/site-packages
prepend-path PYTHONPATH $root/packages

# Alternatively, if TensorFlow was installed into a virtual environment, activate it
set-alias source_tensorflow_env "source $root/venv/bin/activate"

# Set environment variables helpful for TensorFlow to find CUDA and cuDNN
setenv CUDA_HOME /usr/local/cuda-10.1
prepend-path LD_LIBRARY_PATH /usr/local/cuda-10.1/lib64
prepend-path LD_LIBRARY_PATH /usr/local/cuda-10.1/extras/CUPTI/lib64
prepend-path LD_LIBRARY_PATH /opt/cudnn/7.6/lib64

# TensorFlow requires these paths
prepend-path LD_LIBRARY_PATH /usr/local/cuda-10.1/lib64/stubs

