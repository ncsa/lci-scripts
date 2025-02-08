-- *LUA*--

help([[ This is a Open MPI 5.0.1 module]])

-- Local variables
local version = "5.0.1"

-- Whatis description
whatis("Description: OpenMPI")

prepend_path("PATH","/opt/openmpi/5.0.1/bin")
prepend_path("LD_LIBRARY_PATH","/opt/openmpi/5.0.1/lib")
prepend_path("MANPATH", "/opt/openmpi/5.0.1/man")
setenv("MPI_BIN","/opt/openmpi/5.0.1/bin")
setenv("MPI_SYSCONFIG","/opt/openmpi/5.0.1/etc")
setenv("MPI_INCLUDE","/opt/openmpi/5.0.1/include")
setenv("MPI_LIB","/opt/openmpi/5.0.1/lib")
setenv("MPI_MAN","/opt/openmpi/5.0.1/man")
setenv("MPI_COMPILER","openmpi-x86_64")
setenv("MPI_SUFFIX","_openmpi")
setenv("MPI_HOME","/opt/openmpi/5.0.1/")


-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"MPI/gcc/8.5.0/", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("mpi")
