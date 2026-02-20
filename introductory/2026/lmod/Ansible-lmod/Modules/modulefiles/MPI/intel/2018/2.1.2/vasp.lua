-- -*- lua -*-
help([===["VASP 5.4.4 built with intel 2018, OpenMPI 2.1.2"]===])

-- Whatis description
whatis("Description: VASP ")

prepend_path('PATH','/opt/apps/vasp/bin')

add_property("state","testing")
add_property("arch","gpu")
