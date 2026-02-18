-- *LUA*--

help([===[loads the OpenMPI 1.6.5 environment compiled with Intel 2013 ]===])

-- Whatis description
whatis("Description: OpenMPI")

prepend_path{"PATH","/usr/local/openmpi_1.6.5/intel2013/bin",delim=":",priority="0"}
prepend_path{"MANPATH","/usr/local/openmpi_1.6.5/intel2013/share/man",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/usr/local/openmpi_1.6.5/intel2013/lib",delim=":",priority="0"}
prepend_path{"LD_RUN_PATH","/usr/local/openmpi_1.6.5/intel2013/lib",delim=":",priority="0"}
prepend_path{"CPPFLAGS","-I/usr/local/openmpi_1.6.5/intel2013/include",delim=" ",priority="0"}
prepend_path{"LDFLAGS","-L/usr/local/openmpi_1.6.5/intel2013/lib",delim=" ",priority="0"}
setenv("MPI_DIR","/usr/local/openmpi_1.6.5/intel2013/")
setenv("MPI_HOME","/usr/local/openmpi_1.6.5/intel2013/")
setenv("OPENMPI_ROOT","/usr/local/openmpi_1.6.5/intel2013/")
prepend_path{"MODULEPATH","/home/hostadm/Modules/modulefiles/MPI/intel/2013/1.6.5",delim=":",priority="0"}

