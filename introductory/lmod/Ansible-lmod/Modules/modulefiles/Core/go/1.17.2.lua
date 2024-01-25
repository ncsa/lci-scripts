-- -*- lua -*-

help([[ This is a go version go1.17.2 linux/amd64 module to setup MODULEPATH]])

-- Local variables
local version = "1.17.2"

-- Whatis description
whatis("Description:  GO compilers") 

setenv("GOPATH","/home/hostadm/new_go/go")
prepend_path{"PATH","/home/hostadm/new_go/go/bin",delim=":",priority="0"}

-- Setup Modulepath for packages built by this compiler
local mroot = os.getenv("MODULEPATH_ROOT")
local mdir = pathJoin(mroot,"GO/1.17.2", version)
prepend_path("MODULEPATH", mdir)
 
 
-- Set family for this module
family("go_compiler")
