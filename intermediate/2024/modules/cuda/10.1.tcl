#%Module1.0
##
## CUDA 10.1 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads CUDA 10.1 environment."
}

module-whatis "Loads CUDA 10.1 environment"

# Set the CUDA installation directory
set root /usr/local/cuda-10.1

# Set PATH and LD_LIBRARY_PATH
prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib64
prepend-path LD_LIBRARY_PATH $root/extras/CUPTI/lib64

# Set MANPATH
prepend-path MANPATH $root/doc/man

