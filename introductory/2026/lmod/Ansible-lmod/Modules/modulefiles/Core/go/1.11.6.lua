-- -*- lua -*-

help([[ This is a go version go1.11.6 linux/amd64 module to setup MODULEPATH]])

-- Local variables
local version = "1.11.6"

-- Whatis description
whatis("Description:  GO compilers") 

-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"GO/1.11.6", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("go_compiler")
