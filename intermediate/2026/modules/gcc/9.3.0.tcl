#%Module1.0
##
## GCC 9.3.0 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads GCC 9.3.0 environment."
}

module-whatis "Loads GCC 9.3.0 environment"

# Set the GCC installation directory
set root /opt/gcc/9.3.0

# Set PATH, LD_LIBRARY_PATH, and MANPATH
prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib64
prepend-path MANPATH $root/share/man

