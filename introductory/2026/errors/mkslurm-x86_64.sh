#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

SLURMVER=$1
MAKE_J=20 # number of cpus to let make build with
PMIXPATH=/packages/apps/pmix/4.2.8-slurm
UCXVER=1.15.0   # not utilized below
TODAY=$(date +%Y%m%d)

SLURM_DESTDIR=/packages/apps/slurm-x86_64/${SLURMVER}-${TODAY}

if [ -d "$SLURM_DESTDIR" ]; then
    echo "The destination slurm directory '$SLURM_DESTDIR' already exists!"
    # Prompt the user
    read -p "Press 'y' to confirm: " user_input

    # Check the user's input
    if [ "$user_input" = "y" ]; then
        echo "You pressed 'y'."
    else
	exit 1
    fi
fi

# create the dir that holds all the dailies
mkdir -p $SLURMVER
cd $SLURMVER

if [ ! -d "slurm-${SLURMVER}" ]; then
    echo "no slurm source detected, extracting..."
    tar -xf ../slurm-$SLURMVER.tar.bz2
fi

echo "building slurm from source"
cd slurm-$SLURMVER
mkdir -p $SLURM_DESTDIR/lib64/security

make clean || true
./configure \
	--without-shared-libslurm \
	--with-pmix=$PMIXPATH \
	--with-munge \
	--with-hwloc \
	--with-jwt \
	--with-json \
	--enable-slurmrestd \
	--prefix=$SLURM_DESTDIR \
	--with-ucx \
	--with-lua \
	--enable-pam \
	--with-pam_dir=$SLURM_DESTDIR/lib64/security \
	--sysconfdir=/etc/slurm

make -j $MAKE_J
make install
make install-contrib

chown -R software:software $SLURM_DESTDIR
chmod -R o+rX $SLURM_DESTDIR
