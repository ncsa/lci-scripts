help([[
This module loads GCC 9.3.0 environment.
]])

whatis("Name: GCC")
whatis("Version: 9.3.0")
whatis("Category: Compiler")
whatis("Description: GCC 9.3.0 compiler")

local root = "/opt/gcc/9.3.0"

-- Set PATH, LD_LIBRARY_PATH, and MANPATH
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib64"))
prepend_path("MANPATH", pathJoin(root, "share/man"))
