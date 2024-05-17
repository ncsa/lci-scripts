#%Module

module load gcc-11.2.0-gcc-11.2.0
module load hwloc/2.9.3
module load libevent/2.1.12
module load pmix/4.1.3-slurm

if { [module-info mode load] } {
  puts stderr {Loading: hpcx/2.13.1 (NB: provides openmpi 4.1.5a1)}
}

set fn      $ModulesCurrentModulefile
set fn      [file normalize $ModulesCurrentModulefile]

if {[file type $fn] eq "link"} {
set fn [ exec readlink -f $fn]
}

set mydir_base  [ file dirname $fn ]
set mydir_base  [ file dirname $mydir_base ]
set mydir       [ file normalize $mydir_base ]
set hpcx_dir      $mydir
set hpcx_mpi_dir  $hpcx_dir/hpcx-ompi

module-whatis   NVIDIA HPC-X toolkit

setenv HPCX_DIR             $hpcx_dir
setenv HPCX_HOME            $hpcx_dir

setenv HPCX_UCX_DIR         $hpcx_dir/ucx
setenv HPCX_UCC_DIR         $hpcx_dir/ucc
setenv HPCX_SHARP_DIR       $hpcx_dir/sharp
setenv HPCX_HCOLL_DIR       $hpcx_dir/hcoll
setenv HPCX_NCCL_RDMA_SHARP_PLUGIN_DIR  $hpcx_dir/nccl_rdma_sharp_plugin

setenv HPCX_CLUSTERKIT_DIR  $hpcx_dir/clusterkit
setenv HPCX_MPI_DIR         $hpcx_mpi_dir
setenv HPCX_OSHMEM_DIR      $hpcx_mpi_dir
setenv HPCX_IPM_DIR         $hpcx_mpi_dir/tests/ipm-2.0.6
setenv HPCX_IPM_LIB         $hpcx_mpi_dir/tests/ipm-2.0.6/lib/libipm.so
setenv HPCX_MPI_TESTS_DIR   $hpcx_mpi_dir/tests
setenv HPCX_OSU_DIR         $hpcx_mpi_dir/tests/osu-micro-benchmarks-5.8
setenv HPCX_OSU_CUDA_DIR    $hpcx_mpi_dir/tests/osu-micro-benchmarks-5.8-cuda

prepend-path    PATH    $hpcx_dir/ucx/bin
prepend-path    PATH    $hpcx_dir/ucc/bin
prepend-path    PATH    $hpcx_dir/hcoll/bin
prepend-path    PATH    $hpcx_dir/sharp/bin
prepend-path    PATH    $hpcx_mpi_dir/tests/imb
prepend-path    PATH    $hpcx_dir/clusterkit/bin

prepend-path    LD_LIBRARY_PATH $hpcx_dir/ucx/lib
#prepend-path    LD_LIBRARY_PATH $hpcx_dir/ucx/lib/ucx
prepend-path    LD_LIBRARY_PATH $hpcx_dir/ucc/lib
prepend-path    LD_LIBRARY_PATH $hpcx_dir/ucc/lib/ucc
prepend-path    LD_LIBRARY_PATH $hpcx_dir/hcoll/lib
prepend-path    LD_LIBRARY_PATH $hpcx_dir/sharp/lib
prepend-path    LD_LIBRARY_PATH $hpcx_dir/nccl_rdma_sharp_plugin/lib

prepend-path    LIBRARY_PATH $hpcx_dir/ucx/lib
prepend-path    LIBRARY_PATH $hpcx_dir/ucc/lib
prepend-path    LIBRARY_PATH $hpcx_dir/hcoll/lib
prepend-path    LIBRARY_PATH $hpcx_dir/sharp/lib
prepend-path    LIBRARY_PATH $hpcx_dir/nccl_rdma_sharp_plugin/lib

prepend-path    CPATH   $hpcx_dir/hcoll/include
prepend-path    CPATH   $hpcx_dir/sharp/include
prepend-path    CPATH   $hpcx_dir/ucx/include
prepend-path    CPATH   $hpcx_dir/ucc/include
prepend-path    CPATH   $hpcx_mpi_dir/include

prepend-path    PKG_CONFIG_PATH $hpcx_dir/hcoll/lib/pkgconfig
prepend-path    PKG_CONFIG_PATH $hpcx_dir/sharp/lib/pkgconfig
prepend-path    PKG_CONFIG_PATH $hpcx_dir/ucx/lib/pkgconfig
prepend-path    PKG_CONFIG_PATH $hpcx_dir/hpcx-ompi/lib/pkgconfig

prepend-path    MANPATH         $hpcx_mpi_dir/share/man

# Adding MPI runtime
setenv OPAL_PREFIX          $hpcx_mpi_dir
setenv PMIX_INSTALL_PREFIX  $hpcx_mpi_dir
setenv OMPI_HOME            $hpcx_mpi_dir
setenv MPI_HOME             $hpcx_mpi_dir
setenv OSHMEM_HOME          $hpcx_mpi_dir
setenv SHMEM_HOME           $hpcx_mpi_dir

prepend-path    PATH    $hpcx_mpi_dir/bin
prepend-path    LD_LIBRARY_PATH $hpcx_mpi_dir/lib
prepend-path    LIBRARY_PATH $hpcx_mpi_dir/lib

## example code environment variables
set             examples            /packages/publix/sol-mpi-examples
setenv          MPI_EXAMPLES        $examples
