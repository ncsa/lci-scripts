# Apptainer — example definition files

This directory holds the example Apptainer definition files that accompany
**Module 14 — Apptainer** in the LCI Intermediate 2026 workshop. The three
top-level def files are the verbatim sources for the deck's Parts 3 and 4
code slides; the subdirectories are reference material to read after the
talk.

Slide deck: `slides/Current/14-apptainer/14-apptainer.pptx`.

## Layout

```
apptainer/
├── README.md          (this file)
│
│   --- the three deck examples, verbatim ---
├── rocky-yum          slide 14: build from a yum/dnf mirror with a {{ version }} arg
├── rocky-docker       slide 15: same idea bootstrapping from a Docker base image
├── multistage         slide 17: two-stage Go build → tiny Alpine final image
│                                  (includes the inline Go source as a heredoc)
│
│   --- a complete Spack workflow ---
├── spack/
│   ├── README.md      how spack.yaml + `spack containerize` produces gcc.def
│   ├── spack.yaml     a small Spack environment with gcc, zlib-ng, 7zip, tcl, lua
│   └── gcc.def        the Apptainer def file Spack generated from spack.yaml
│
│   --- a real-world MPI-aware container recipe ---
└── openfoam/
    ├── README.md      the CIQ blog's site-MPI + OpenFOAM walkthrough
    └── containers/    multiple OpenFOAM def variants (Rocky, Leap, dev, run)

│   --- a copy of the upstream Apptainer examples gallery ---
└── examples/
    ├── README.md
    ├── alpine, busybox, debian, ubuntu, rocky, almalinux, centos, fedora,
    │     opensuse, sle, arch, raspbian, library, shub, ...
    ├── scratch/       Apptainer.alpine, Apptainer.busybox — minimal scratch builds
    ├── multistage/    upstream copy of the multistage Go example
    ├── self/          a container that builds itself
    ├── instances/     long-running service-style containers
    ├── apps/          %appinstall / %apphelp / %apprun multi-app SCIF pattern
    ├── scientific/    bare-minimum yum-bootstrap scientific Linux
    ├── build-apptainer/ Apptainer that builds Apptainer
    └── ...-arm64/     ARM64 variants of the above
```

## Which example teaches what

| File / dir                              | Concept                                                                              | Mentioned in deck slide               |
|------------------------------------------|--------------------------------------------------------------------------------------|---------------------------------------|
| `rocky-yum`                              | `Bootstrap: yum` + `Include: dnf` + `MirrorURL:` + `%arguments`                       | 14                                    |
| `rocky-docker`                           | `Bootstrap: docker` + `From:` for a Docker base image                                | 15                                    |
| `multistage`                             | Two-stage build: full Go toolchain → tiny Alpine final; inline Go source via heredoc | 17                                    |
| `spack/spack.yaml` + `spack/gcc.def`     | Input and output of `spack containerize` — Spack-generated reproducible image        | 18                                    |
| `openfoam/README.md`                     | Site-MPI + OpenFOAM via `Bootstrap: localimage` multistage — answer to "MPI in containers" | 20 (bundle pointer)                   |
| `examples/`                              | 30+ canonical base templates — copy and customize                                    | 20 (bundle pointer)                   |
| `examples/apps/Apptainer.cowsay`         | SCIF multi-app pattern (`%appinstall`, `%apphelp`, `%apprun`)                        | 20 (bundle pointer)                   |
| `examples/scratch/Apptainer.alpine`      | Minimal-as-possible base                                                             | —                                     |
| `examples/self/Apptainer`                | A container that builds itself                                                       | —                                     |

## How to build any of these

```bash
# The three top-level deck examples:
apptainer build --build-arg version="8" rocky8.sif rocky-yum
apptainer build --build-arg version="9.3" rocky93.sif rocky-docker
apptainer build gohello.sif multistage

# From the spack workflow:
cd spack
apptainer build gcc.sif gcc.def

# From the upstream examples gallery (the def file is always named "Apptainer"):
apptainer build alpine.sif examples/alpine/Apptainer
apptainer build cowsay.sif examples/apps/Apptainer.cowsay
```

`--build-arg KEY=VALUE` can be repeated, or set `BUILDARG_KEY` env vars
before the build instead.

## Security note

Every example is designed to be built and run as the invoking user. None
require a root daemon. `apptainer build` writes a single `.sif` file that
is read-only at runtime, signable, and runs under the same UID/GID as
whoever launched it — that's the whole HPC security story from Part 1 of
the deck.

## See also

- Slide deck: `slides/Current/14-apptainer/14-apptainer.pptx`
- Apptainer user + admin docs: <https://apptainer.org/docs>
- NIH-HPC singularity-def-files gallery: <https://github.com/NIH-HPC/singularity-def-files>
- CIQ blog (MPI, OpenFOAM, Slurm integration): <https://ciq.com/blog>
