help([[
This module loads OpenFOAM 2312 environment.
]])

whatis("Name: OpenFOAM 2312")
whatis("Version: 2312")
whatis("Category: Application")
whatis("Description: Loads OpenFOAM 2312 environment")

-- Set the OpenFOAM installation directory
local root = "/path/to/OpenFOAM-2312"

-- Load dependencies
-- load("gcc/9.2.0")
-- load("openmpi/4.0.3")

-- Set environment variables
setenv("FOAM_ROOT", root)
setenv("WM_PROJECT", "OpenFOAM")
setenv("WM_PROJECT_VERSION", "2312")

-- OpenFOAM-specific environment variables
setenv("FOAM_APP", pathJoin(root, "applications"))
setenv("FOAM_SRC", pathJoin(root, "src"))
setenv("FOAM_USER_APPBIN", pathJoin(root, "platforms/linux64GccDPInt32Opt/bin"))
setenv("FOAM_USER_LIBBIN", pathJoin(root, "platforms/linux64GccDPInt32Opt/lib"))

-- Prepend to the PATH and LD_LIBRARY_PATH
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("PATH", pathJoin(root, "platforms/linux64GccDPInt32Opt/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "platforms/linux64GccDPInt32Opt/lib"))

-- Aliases (Optional)
set_alias("foam", "source " .. pathJoin(root, "etc/bashrc"))
