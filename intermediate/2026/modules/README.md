# Modules — example modulefiles for Lmod and Environment Modules

This directory holds the example modulefiles that accompany **Module 13 —
Software Modules** in the LCI Intermediate 2026 workshop. Every package
ships in TCL (Environment Modules format) and most also in Lua (Lmod
format), so you can read the same install side-by-side in both syntaxes.

Slide deck: `slides/Current/13-modules/13-modules.pptx`.

## Layout

```
modules/
├── README.md             (this file)
├── letsbuildpython.sh    build Python from source AND auto-generate its .lua modulefile
├── python/
│   ├── 3.8.{tcl,lua}     matched TCL/Lua pair — the side-by-side example on slide 13
│   └── 3.12.{tcl,lua}    same package, current version
├── tensorflow/
│   └── 2.3.0.{tcl,lua}   uses load("python/3.8"), load("gcc/9.3.0"), ... — the dependency-cascade example on slide 14
├── cuda/    10.1.{tcl,lua}
├── cudnn/   7.6.{tcl,lua}
├── gcc/     9.3.0.{tcl,lua}
├── openfoam/ 2312.{tcl,lua}
├── hwloc/   2.9.3.tcl     TCL-only — uses module-info introspection (RC_* metadata)
└── hpcx/    2.17.1.tcl    TCL-only — relative-path introspection via $ModulesCurrentModulefile
```

## Which example teaches what

| Package        | Concept                                                                                              | Mentioned in deck slide               |
|----------------|-------------------------------------------------------------------------------------------------------|---------------------------------------|
| `python/3.8`   | Identical install in TCL vs Lua — read both, then `diff 3.8.tcl 3.8.lua`                              | 13 (side-by-side)                     |
| `python/3.12`  | Current-version mirror of `3.8`                                                                       | —                                     |
| `tensorflow`   | Lmod `load()` cascade — one `module load` resolves the whole stack                                    | 14 (dependency cascade)               |
| `hpcx`         | Relative-path introspection in TCL via `$ModulesCurrentModulefile` — TCL twin of the Lmod technique  | speaker notes, 13                     |
| `letsbuildpython.sh` | Build a package from source AND auto-generate its `.lua` modulefile (production pattern)        | 13 + 16 (bundle pointer)              |
| `cuda`, `cudnn`, `gcc`, `openfoam`, `hwloc` | Minimal real-world templates — good copy-and-modify starting points                | 16 (bundle pointer)                   |

## Conventions

All installs use one of two install-prefix layouts, consistent across the
bundle:

- `/opt/<package>/<version>` for source-built things (`python`, `gcc`,
  `cudnn`, `openfoam`, `tensorflow`).
- `/usr/local/cuda-<version>` for vendor packages (`cuda`).

Paths are real — none of the modulefiles ship with `/path/to/...`
placeholders. They reflect where you'd install if you ran
`letsbuildpython.sh 3.12` (or the equivalent for the other packages).

UID/GID and modulefile install location:

- Modulefiles go under `/usr/share/modulefiles/<package>/<version>.{lua,tcl}`
  (the default Lmod `MODULEPATH` on RHEL-family).
- `letsbuildpython.sh` writes its output there directly. Adjust
  `MODULE_FILE_DIR` in the script if your site uses a different path.

## How to use one of these on a cluster

```bash
# Install the package itself (example for python 3.12):
./letsbuildpython.sh 3.12

# Or copy a modulefile into MODULEPATH by hand:
sudo mkdir -p /usr/share/modulefiles/python
sudo cp python/3.12.lua /usr/share/modulefiles/python/

# Load it:
module avail python
module load python/3.12
module list
python --version
```

## See also

- Slide deck: `slides/Current/13-modules/13-modules.pptx`
- Lmod docs: <https://lmod.readthedocs.io/>
- Environment Modules docs: <https://modules.sourceforge.net/>
