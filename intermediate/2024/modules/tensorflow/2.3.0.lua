help([[
This module loads TensorFlow 2.3.0 with its dependencies.
]])

whatis("Name: TensorFlow")
whatis("Version: 2.3.0")
whatis("Category: Machine Learning, Deep Learning")
whatis("Description: TensorFlow environment")

-- Load dependencies
load("python/3.8")
load("gcc/9.3.0")
load("cuda/10.1")
load("cudnn/7.6")

-- PYTHONPATH
local packages_path = "/path/to/python/packages"
prepend_path("PYTHONPATH", packages_path)

-- You may want to add the site-packages directory of the Python environment where TensorFlow is installed
prepend_path("PYTHONPATH", "/path/to/python3.8/site-packages")

-- Alternatively, if TensorFlow was installed using a Python virtual environment, activate it
set_alias("source_tensorflow_env", "source /path/to/tensorflow-venv/bin/activate")

-- Set environment variables for CUDA and cuDNN
setenv("CUDA_HOME", "/usr/local/cuda-10.1")
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/lib64")
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/extras/CUPTI/lib64")
prepend_path("LD_LIBRARY_PATH", "/path/to/cudnn/7.6/lib64")

-- TensorFlow requires these paths
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/lib64/stubs")
