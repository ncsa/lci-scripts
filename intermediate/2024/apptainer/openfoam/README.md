
[CIQ Blog - Integrate MPI for OpenFOAM](https://ciq.com/blog/integrating-site-specific-mpi-with-an-openfoam-official-apptainer-image-on-slurm-managed-hpc-environments/)

### Building Rocky Linux 8 based OpenFOAM Image
cd openfoam/containers
apptianer build openfoam2306.sif openfoam-run_rocky-template.def

### Building Rocky Linux 8 based OpenMPI wtih Slurm PMI-2 Image
Create pmi2-ompi4.def with the following contents:
```shell
Bootstrap: docker
From: rockylinux/rockylinux:latest

%post
    dnf -y group install "Development tools"
    dnf -y install epel-release
    crb enable
    dnf -y install wget
    dnf -y install hwloc slurm-pmi slurm-pmi-devel
    dnf -y clean all
    wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.4.tar.gz
    tar zxvf openmpi-4.1.4.tar.gz && rm openmpi-4.1.4.tar.gz
    cd openmpi-4.1.4
    ./configure --with-hwloc=internal --prefix=/opt/openmpi/4.1.4 \
      --with-slurm --with-pmi=/usr
    make -j $(nproc)
    make install
```

Build pmi2-ompi4.sif Image

```shell
apptainer build pmi2-ompi4.sif pmi2-ompi4.def
```

### Integrate Site-Specific MPI to the Rocky Linux 8-based OpenFOAM Image

Create pmi2-openfoam2306.def with the following content:

```shell
Bootstrap: localimage
From: pmi2-ompi4.sif
Stage: mpi

Bootstrap: localimage
From: openfoam2306.sif
Stage: runtime

%files from mpi
    /opt/openmpi/4.1.4 /opt/openmpi/4.1.4

%post
    dnf -y install slurm-pmi
    dnf -y clean all

%post
    echo 'export MPI_ARCH_PATH=/opt/openmpi/4.1.4' > $(bash /openfoam/assets/query.sh -show-prefix)/etc/config.sh/prefs.sys-openmpi

%runscript
    exec /openfoam/run "$@"
```

Build pmi2-openfoam2306.sif Image

```shell
apptainer build pmi2-openfoam2306.sif pmi2-openfoam2306.def
```
Move image to ~/.local/bin 
```shell
mv pmi2-openfoam2306.sif ~/.local/bin
```






















