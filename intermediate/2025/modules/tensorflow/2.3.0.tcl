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

# Set PYTHONPATH and other Python-related paths
setenv PYTHONPATH /path/to/python/packages:$PYTHONPATH

# You may want to add the site-packages directory of the Python environment where TensorFlow is installed
prepend-path PYTHONPATH /path/to/python3.8/site-packages

# Alternatively, if TensorFlow was installed using a Python virtual environment, activate it
set-alias source_tensorflow_env "source /path/to/tensorflow-venv/bin/activate"

# Set environment variables helpful for TensorFlow to find CUDA and cuDNN
setenv CUDA_HOME /usr/local/cuda-10.1
setenv LD_LIBRARY_PATH /usr/local/cuda-10.1/lib64:/usr/local/cuda-10.1/extras/CUPTI/lib64:$LD_LIBRARY_PATH
prepend-path LD_LIBRARY_PATH /path/to/cudnn/7.6/lib64

# TensorFlow requires these paths
prepend-path LD_LIBRARY_PATH /usr/local/cuda-10.1/lib64/stubs

