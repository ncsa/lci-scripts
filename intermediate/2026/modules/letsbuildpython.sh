#!/bin/bash

# Check if Python version is provided as an argument
if [ -z "$1" ]; then
	echo "Usage: $0 <python-version>"
	exit 1
fi

# Set variables
PYTHON_VERSION="$1"
INSTALL_PREFIX="/opt/apps/python/$PYTHON_VERSION"
MODULE_FILE_DIR="/usr/share/modulefiles"
MODULE_FILE_NAME="python/$PYTHON_VERSION"

# Download and extract Python source
cd /tmp
wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar xzf Python-$PYTHON_VERSION.tgz
cd Python-$PYTHON_VERSION

# Configure and install Python
./configure --prefix=$INSTALL_PREFIX
make -j$(nproc)
make altinstall

# Install additional Python packages
$INSTALL_PREFIX/bin/pip${PYTHON_VERSION%.*} install numpy scipy pandas

# Create the module file directory if it doesn't exist
mkdir -p $MODULE_FILE_DIR/$(dirname $MODULE_FILE_NAME)

# Write the module file
cat <<EOL >$MODULE_FILE_DIR/$MODULE_FILE_NAME.lua
--%Module

local version = "$PYTHON_VERSION"
local install_dir = pathJoin("/opt/apps/python", version)

whatis("Name: Python")
whatis("Version: ".. version)
whatis("Description: Python ".. version)

prepend_path("PATH", pathJoin(install_dir, "bin"))
prepend_path("MANPATH", pathJoin(install_dir, "share/man"))
prepend_path("LD_LIBRARY_PATH", pathJoin(install_dir, "lib"))
prepend_path("PKG_CONFIG_PATH", pathJoin(install_dir, "lib/pkgconfig"))
prepend_path("CMAKE_PREFIX_PATH", install_dir)
EOL

cd $INSTALL_PREFIX/bin
ln -s python${PYTHON_VERSION%.*} python
ln -s pip${PYTHON_VERSION%.*} pip

# Update PIP
cd $INSTALL_PREFIX/bin
./pip install --upgrade pip

echo "Python $PYTHON_VERSION installed to $INSTALL_PREFIX"
echo "Module file created at $MODULE_FILE_DIR/$MODULE_FILE_NAME.lua"
