#%Module1.0
proc ModulesHelp { } {
  puts stderr "Portable Hardware Locality (hwloc) 2.9.3"
}
module-whatis "Portable Hardware Locality (hwloc) 2.9.3"

if { [module-info mode load] } {
  puts stderr {
  }
}

set topdir /packages/apps/hwloc/2.9.3

prepend-path     PATH               $topdir/bin:$topdir/sbin
prepend-path     LD_LIBRARY_PATH    $topdir/lib
prepend-path     INCLUDE            $topdir/include
#prepend-path     MANPATH            $topdir/man
prepend-path     MANPATH            $topdir/share/man
#prepend-path     INFOPATH           $topdir/share/info
#unsetenv        LD_LIBRARY_PATH

if { [module-info mode display] } {
    # RC FIELDS
    setenv RC_8X "1"
    setenv RC_PKG_MANAGER "1"
    setenv RC_OOD     "0"
    setenv RC_NOLOGIN "0"
    setenv RC_DEPRECATED "0"
    setenv RC_EXPERIMENTAL "0"
    setenv RC_DISCOURAGED "0"
    setenv RC_RETIRED "0"
    setenv RC_VIRTUAL "0"

    setenv RC_TAGS "hwloc"
    setenv RC_DESCRIPTION "hwloc 2.9.3"
    setenv RC_URL "https://www.open-mpi.org/software/hwloc/v2.9/"
    setenv RC_NOTES "Portable Hardware Locality"

    setenv RC_INSTALL_DATE "2023-10-17"
    setenv RC_INSTALLER "acchapm1"
  }
