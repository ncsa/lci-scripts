-- *LUA*--

help([===[loads the OpenMPI 2.1.2 environment compiled with Intel 2018 ]===])

-- Whatis description
whatis("Description: OpenMPI")

local version="2.1.2"

prepend_path{"PATH","/opt/apps/openmpi_2.1.2/intel/bin",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/openmpi_2.1.2/intel/share/man",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/openmpi_2.1.2/intel/lib",delim=":",priority="0"}
prepend_path{"LD_RUN_PATH","/opt/apps/openmpi_2.1.2/intel/lib",delim=":",priority="0"}
prepend_path{"CPPFLAGS","-I/opt/apps/openmpi_2.1.2/intel/include",delim=" ",priority="0"}
prepend_path{"LDFLAGS","-L/opt/apps/openmpi_2.1.2/intel/lib",delim=" ",priority="0"}
setenv("MPI_DIR","/opt/apps/openmpi_2.1.2/intel/")
setenv("MPI_HOME","/opt/apps/openmpi_2.1.2/intel/")
setenv("OPENMPI_ROOT","/opt/apps/openmpi_2.1.2/intel/")
prepend_path{"MODULEPATH","/home/hostadm/Modules/MPI/intel/2018/2.1.2",delim=":",priority="0"}

-- Setup Modulepath for packages built by this MPI 
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"MPI/intel/2018", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("mpi")

