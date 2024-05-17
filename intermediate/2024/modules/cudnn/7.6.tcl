#%Module1.0
##
## cuDNN 7.6 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads cuDNN 7.6 environment."
}

module-whatis "Loads cuDNN 7.6 environment"

# Set the cuDNN installation directory
set root /path/to/cudnn/7.6

# Set LD_LIBRARY_PATH
prepend-path LD_LIBRARY_PATH $root/lib64

