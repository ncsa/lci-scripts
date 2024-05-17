#%Module1.0
##
## OpenFOAM 2312 modulefile
##

proc ModulesHelp { } {
    puts stderr "This module loads OpenFOAM 2312 environment."
}

module-whatis "Loads OpenFOAM 2312 environment"

# Set the OpenFOAM installation directory
setenv FOAM_ROOT /path/to/OpenFOAM-2312

# Load the dependencies or prerequisite modules if necessary
# module load gcc/9.2.0
# module load openmpi/4.0.3

# Set environment variables
setenv WM_PROJECT OpenFOAM
setenv WM_PROJECT_VERSION 2312

# Set the OpenFOAM-specific environment variables
setenv FOAM_APP $FOAM_ROOT/applications
setenv FOAM_SRC $FOAM_ROOT/src
setenv FOAM_USER_APPBIN $FOAM_ROOT/platforms/linux64GccDPInt32Opt/bin
setenv FOAM_USER_LIBBIN $FOAM_ROOT/platforms/linux64GccDPInt32Opt/lib

# Set PATH and LD_LIBRARY_PATH
prepend-path PATH $FOAM_ROOT/bin
prepend-path PATH $FOAM_USER_APPBIN
prepend-path LD_LIBRARY_PATH $FOAM_USER_LIBBIN

# Aliases for ease of use (Optional)
set-alias foam "source $FOAM_ROOT/etc/bashrc"

