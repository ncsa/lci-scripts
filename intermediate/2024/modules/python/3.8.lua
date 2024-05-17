help([[
This module loads Python 3.8 environment.
]])

whatis("Name: Python")
whatis("Version: 3.8")
whatis("Category: Language")
whatis("Description: Python 3.8 programming language environment")

local root = "/opt/python/3.8"

-- Set PATH and other environment variables
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH", pathJoin(root, "share/man"))
prepend_path("PYTHONPATH", pathJoin(root, "lib/python3.8/site-packages"))

-- Set aliases for Python and pip
set_alias("python", pathJoin(root, "bin/python3"))
set_alias("pip", pathJoin(root, "bin/pip3"))
