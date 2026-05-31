help([[
This module loads Python 3.12 environment.
]])

whatis("Name: Python")
whatis("Version: 3.12")
whatis("Category: Language")
whatis("Description: Python 3.12 programming language environment")

local root = "/opt/python/3.12"

-- Set PATH and other environment variables
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH", pathJoin(root, "share/man"))
prepend_path("PYTHONPATH", pathJoin(root, "lib/python3.12/site-packages"))

-- Set aliases for Python and pip
set_alias("python", pathJoin(root, "bin/python3"))
set_alias("pip", pathJoin(root, "bin/pip3"))
