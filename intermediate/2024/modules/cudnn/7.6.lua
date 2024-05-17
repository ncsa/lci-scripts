help([[
This module loads cuDNN 7.6 environment.
]])

whatis("Name: cuDNN")
whatis("Version: 7.6")
whatis("Category: Library")
whatis("Description: CUDA Deep Neural Network library")

local root = "/path/to/cudnn/7.6"

-- Set LD_LIBRARY_PATH
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib64"))
