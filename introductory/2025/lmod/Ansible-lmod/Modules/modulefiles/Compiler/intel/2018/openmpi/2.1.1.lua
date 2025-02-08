-- *LUA*--

help([===[loads the OpenMPI 2.1.1 environment compiled with Intel 2018 ]===])

-- Whatis description
whatis("Description: OpenMPI")

prepend_path{"PATH","/usr/local/openmpi_2.1.1/intel/bin",delim=":",priority="0"}
prepend_path{"MANPATH","/usr/local/openmpi_2.1.1/intel/share/man",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/usr/local/openmpi_2.1.1/intel/lib",delim=":",priority="0"}
prepend_path{"LD_RUN_PATH","/usr/local/openmpi_2.1.1/intel/lib",delim=":",priority="0"}
prepend_path{"CPPFLAGS","-I/usr/local/openmpi_2.1.1/intel/include",delim=" ",priority="0"}
prepend_path{"LDFLAGS","-L/usr/local/openmpi_2.1.1/intel/lib",delim=" ",priority="0"}
setenv("MPI_DIR","/usr/local/openmpi_2.1.1/intel/")
setenv("MPI_HOME","/usr/local/openmpi_2.1.1/intel/")
setenv("OPENMPI_ROOT","/usr/local/openmpi_2.1.1/intel/")
prepend_path{"MODULEPATH","/home/hostadm/Modules/modulefiles/MPI/intel/2018/2.1.1",delim=":",priority="0"}

