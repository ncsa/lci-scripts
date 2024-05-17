help([[
This module loads CUDA 10.1 environment.
]])

whatis("Name: CUDA")
whatis("Version: 10.1")
whatis("Category: Library")
whatis("Description: CUDA Toolkit 10.1")

local root = "/usr/local/cuda-10.1"

-- Set PATH and LD_LIBRARY_PATH
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib64"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "extras/CUPTI/lib64"))

-- Set MANPATH
prepend_path("MANPATH", pathJoin(root, "doc/man"))
