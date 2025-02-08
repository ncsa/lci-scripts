-- -*- lua -*-
help([===[loads the INTEL 2013 sp1.0.080 C/C++/Fortran environment ]===])

-- Whatis description
whatis("Description: Intel compilers ") 


local version="2013"

prepend_path{"CPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb/include",delim=":",priority="0"}
prepend_path{"CPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/include",delim=":",priority="0"}
setenv("MKLROOT","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl")
setenv("GDB_CROSS","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/intel64_mic/py27/bin/gdb-mic")
prepend_path{"MIC_LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb/lib/mic",delim=":",priority="0"}
prepend_path{"MIC_LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/lib/mic",delim=":",priority="0"}
prepend_path{"MIC_LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/mic",delim=":",priority="0"}
prepend_path{"MIC_LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mpirt/lib/mic",delim=":",priority="0"}
prepend_path{"MIC_LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/mic",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/intel64/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/intel64/py27/share/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/intel64_mic/py27/share/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/lib/intel64/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp/lib/intel64/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"NLSPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/intel64/locale/%l_%t/%N",delim=":",priority="0"}
prepend_path{"MIC_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb/lib/mic",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb/lib/intel64/gcc4.1",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/lib/intel64",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp/lib/intel64",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp/../compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb/lib/intel64/gcc4.1",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp/../compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mpirt/lib/intel64",delim=":",priority="0"}
prepend_path{"LD_LIBRARY_PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/compiler/lib/intel64",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/man/en_US",delim=":",priority="0"}
prepend_path{"MANPATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/man/en_US",delim=":",priority="0"}
append_path{"MANPATH","",delim=":",priority="0"}
setenv("GDBSERVER_MIC","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/target/mic/bin/gdbserver")
setenv("TBBROOT","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/tbb")
setenv("IPPROOT","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/ipp")
append_path{"INTEL_LICENSE_FILE","/opt/apps/intel2013/licenses",delim=":",priority="0"}
setenv("IDB_HOME","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/bin/intel64")
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gui/intel64",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/bin/intel64_mic",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/bin/intel64",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/intel64/py27/bin",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/debugger/gdb/intel64_mic/py27/bin",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mpirt/bin/intel64",delim=":",priority="0"}
prepend_path{"PATH","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/bin/intel64",delim=":",priority="0"}
prepend_path{"INCLUDE","/opt/apps/intel2013/composer_xe_2013_sp1.0.080/composer_xe_2013_sp1.0.080/mkl/include",delim=":",priority="0"}

-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"Compiler/intel", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("compiler")

