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

-- TensorFlow's own install tree
local root = "/opt/tensorflow/2.3.0"

-- PYTHONPATH: the python/3.8 site-packages directory where TensorFlow was pip-installed
prepend_path("PYTHONPATH", "/opt/python/3.8/lib/python3.8/site-packages")
prepend_path("PYTHONPATH", pathJoin(root, "packages"))

-- Alternatively, if TensorFlow was installed into a virtual environment, activate it
set_alias("source_tensorflow_env", "source " .. pathJoin(root, "venv/bin/activate"))

-- Set environment variables for CUDA and cuDNN
setenv("CUDA_HOME", "/usr/local/cuda-10.1")
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/lib64")
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/extras/CUPTI/lib64")
prepend_path("LD_LIBRARY_PATH", "/opt/cudnn/7.6/lib64")

-- TensorFlow requires these paths
prepend_path("LD_LIBRARY_PATH", "/usr/local/cuda-10.1/lib64/stubs")
