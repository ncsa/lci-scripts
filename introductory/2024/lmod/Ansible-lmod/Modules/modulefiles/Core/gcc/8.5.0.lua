-- -*- lua -*-

help([[ This is a gcc 8.5.0 compiler, came with Debian 10 packages]])

-- Local variables
local version = "8.5.0"

-- Whatis description
whatis("Description: GCC compiler") 

-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"Compiler/gcc", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("compiler")
