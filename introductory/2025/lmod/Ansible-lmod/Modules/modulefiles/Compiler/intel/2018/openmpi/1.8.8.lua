-- *LUA*--

help([===[loads the OpenMPI 1.8.8 environment compiled with Intel 2018 ]===])

-- Whatis description
whatis("Description: OpenMPI")

prepend_path{"PATH","/usr/local/openmpi_1.8.8/intel/bin",delim=":",priority="0"}
prepend_path{"MANPATH","/usr/local/openmpi_1.8.8/intel/share/man",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/usr/local/openmpi_1.8.8/intel/lib",delim=":",priority="0"}
prepend_path{"LD_RUN_PATH","/usr/local/openmpi_1.8.8/intel/lib",delim=":",priority="0"}
prepend_path{"CPPFLAGS","-I/usr/local/openmpi_1.8.8/intel/include",delim=" ",priority="0"}
prepend_path{"LDFLAGS","-L/usr/local/openmpi_1.8.8/intel/lib",delim=" ",priority="0"}
setenv("MPI_DIR","/usr/local/openmpi_1.8.8/intel/")
setenv("MPI_HOME","/usr/local/openmpi_1.8.8/intel/")
setenv("OPENMPI_ROOT","/usr/local/openmpi_1.8.8/intel/")
prepend_path{"MODULEPATH","/home/hostadm/Modules/modulefiles/MPI/intel/2018/1.8.8",delim=":",priority="0"}

