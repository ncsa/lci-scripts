-- -*- lua -*-
help([===[loads the INTEL 2018 0.128 C/C++/Fortran environment ]===])

-- Whatis description
whatis("Description: Intel compilers ") 

local version="2018"

prepend_path{"MANPATH","/opt/apps/intel/documentation_2018/en/debugger//gdb-igfx/man/",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/intel/documentation_2018/en/debugger//gdb-ia/man/",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi/man",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/intel/man/common",delim=":",priority="0"}
append_path{"MANPATH","",delim=":",priority="0"}
setenv("MKLROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mkl")
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/daal/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/lib/intel64/gcc4.7",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/lib/intel64/gcc4.7",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/compiler/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/ipp/lib/intel64",delim=":",priority="0"}
prepend_path{"CLASSPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/daal/lib/daal.jar",delim=":",priority="0"}
prepend_path{"CLASSPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/lib/mpi.jar",delim=":",priority="0"}
setenv("PSTLROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/pstl")
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/daal/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/pstl/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mkl/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/ipp/include",delim=":",priority="0"}
setenv("GDBSERVER_MIC","/opt/apps/intel/debugger_2018/gdb/targets/intel64/x200/bin/gdbserver")
setenv("GDB_CROSS","/opt/apps/intel/debugger_2018/gdb/intel64/bin/gdb-ia")
setenv("IPPROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/ipp")
setenv("INTEL_PYTHONHOME","/opt/apps/intel/debugger_2018/python/intel64/")
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/daal/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/debugger_2018/libipt/intel64/lib",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/debugger_2018/iga/lib",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/lib/intel64/gcc4.7",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb/lib/intel64/gcc4.7",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/compiler/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/ipp/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi/mic/lib",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/lib",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/compiler/lib/intel64_lin",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/bin",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/bin/intel64",delim=":",priority="0"}
setenv("MPM_LAUNCHER","/opt/apps/intel/debugger_2018/mpm/mic/bin/start_mpm.sh")
prepend_path{"NLSPATH","/opt/apps/intel/debugger_2018/gdb/intel64/share/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/compiler/lib/intel64/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"INFOPATH","/opt/apps/intel/documentation_2018/en/debugger//gdb-igfx/info/",delim=":",priority="0"}
prepend_path{"INFOPATH","/opt/apps/intel/documentation_2018/en/debugger//gdb-ia/info/",delim=":",priority="0"}
setenv("DAALROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/daal")
setenv("I_MPI_ROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/mpi")
setenv("TBBROOT","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/tbb")
append_path{"INTEL_LICENSE_FILE","/opt/apps/intel/compilers_and_libraries_2018.0.128/linux/licenses",delim=":",priority="0"}
append_path{"INTEL_LICENSE_FILE","/opt/apps/intel/licenses",delim=":",priority="0"}

-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"Compiler/intel", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("compiler")

