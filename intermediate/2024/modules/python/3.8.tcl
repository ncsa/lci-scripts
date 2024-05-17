#%Module1.0
##
## Python 3.8 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads Python 3.8 environment."
}

module-whatis "Loads Python 3.8 environment"

# Set the Python installation directory
set root /opt/python/3.8

# Set PATH and other environment variables
prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib
prepend-path MANPATH $root/share/man
prepend-path PYTHONPATH $root/lib/python3.8/site-packages

# Set this Python as the default interpreter
set-alias python $root/bin/python3
set-alias pip $root/bin/pip3

