# Apptainer — example definition files

This directory holds the example Apptainer definition files and reference
material that accompany the **Apptainer** module in the LCI Intermediate 2026
workshop. The deck's Parts 3 and 4 code slides are sourced verbatim from the
def files under `examples/`; the `spack/`, `openfoam/`, and the rest of the
`examples/` gallery are reference material to read after the talk.

Slide deck: `slides/Current/14-apptainer/14-apptainer.pptx`.

## Layout

```
apptainer/
├── README.md                       (this file)
│
│   --- signing reference (Part 1 / security) ---
├── apptainer-key.md                PGP key management: create & publish a signing key
├── apptainer-key-commands          a cheat sheet of `apptainer key` / `sign` / `verify`
├── Apptainer-QuickReference.pdf    one-page printable command reference
│
│   --- a complete Spack workflow ---
├── spack/
│   ├── README.md                   how spack.yaml + `spack containerize` produces gcc.def
│   ├── spack.yaml                  a small Spack environment with gcc, zlib-ng, 7zip, tcl, lua
│   └── gcc.def                     the Apptainer def file Spack generated from spack.yaml
│
│   --- a real-world MPI-aware container recipe ---
├── openfoam/
│   ├── README.md                   the CIQ blog's site-MPI + OpenFOAM walkthrough
│   └── containers/                 OpenFOAM def variants (dev + run; Rocky & Leap)
│       ├── openfoam-dev.def
│       ├── openfoam-dev_rocky.def
│       ├── openfoam-dev_leap.def
│       ├── openfoam-run-templete.def
│       ├── openfoam-run_rocky-template.def
│       └── openfoam-run_leap-template.def
│
│   --- the upstream Apptainer examples gallery (plus the deck examples) ---
└── examples/
    ├── README.md
    │
    │   --- the deck examples, verbatim (these are files, not folders) ---
    ├── rocky-yum                   build from a yum/dnf mirror with a {{ version }} arg
    ├── rocky-docker                same idea bootstrapping from a Docker base image
    │
    │   --- distro base templates (each folder holds a def file named "Apptainer") ---
    ├── almalinux/ arch/ busybox/ centos/ debian/ docker/ fedora/ library/
    │     opensuse/ raspbian/ rocky/ scientific/ shub/ sle/ ubuntu/
    ├── *-arm64/                     ARM64 variants: almalinux, centos, fedora, opensuse
    │
    │   --- pattern / advanced examples ---
    ├── multistage/                  two-stage Go build → tiny Alpine final image
    ├── apps/                        %appinstall / %apphelp / %apprun multi-app SCIF pattern
    │                                  (Apptainer + Apptainer.cowsay)
    ├── scratch/                     Apptainer.alpine, Apptainer.busybox — minimal scratch builds
    ├── self/                        a container that builds itself
    ├── instances/                   long-running service-style containers
    ├── asciinema/                   records a terminal session from inside the container
    ├── build-apptainer/             an Apptainer that builds Apptainer (build-apptainer.def)
    └── plugins/                     Go plugin examples (cli, config, log, ubuntu-userns-overlay)
```

## Which example teaches what

| File / dir                              | Concept                                                                              |
|------------------------------------------|--------------------------------------------------------------------------------------|
| `examples/rocky-yum`                     | `bootstrap: yum` + `include: dnf` + `mirrorurl:` + `%arguments` with `{{ version }}` |
| `examples/rocky-docker`                  | `Bootstrap: docker` + `From:` for a Docker base image, with a `{{ version }}` arg    |
| `examples/multistage/Apptainer`          | Two-stage build: full Go toolchain → tiny Alpine final; inline Go source via heredoc |
| `spack/spack.yaml` + `spack/gcc.def`     | Input and output of `spack containerize` — Spack-generated reproducible image        |
| `openfoam/README.md` + `containers/`     | Site-MPI + OpenFOAM via multistage `dev` → `run` templates — "MPI in containers"     |
| `examples/`                              | 20+ canonical base templates — copy and customize                                    |
| `examples/apps/Apptainer.cowsay`         | SCIF multi-app pattern (`%appinstall`, `%appenv`, `%apprun`)                          |
| `examples/scratch/Apptainer.alpine`      | Minimal-as-possible base                                                              |
| `examples/self/Apptainer`                | A container that builds itself                                                        |
| `examples/plugins/`                      | Writing Apptainer plugins in Go (CLI, config, log, userns-overlay)                   |
| `apptainer-key.md` + `apptainer-key-commands` | Signing & verifying SIF images; publishing a PGP key to `keys.openpgp.org`       |

## How to build any of these

```bash
# The two deck examples (now under examples/ — note the version build-arg):
apptainer build --build-arg version="8"   rocky8.sif  examples/rocky-yum
apptainer build --build-arg version="9.3" rocky93.sif examples/rocky-docker

# The multistage Go example:
apptainer build gohello.sif examples/multistage/Apptainer

# From the spack workflow:
cd spack
apptainer build gcc.sif gcc.def

# From the upstream examples gallery (the def file is always named "Apptainer"):
apptainer build alpine.sif  examples/alpine/Apptainer   # ...where such a folder exists
apptainer build cowsay.sif  examples/apps/Apptainer.cowsay
```

`--build-arg KEY=VALUE` can be repeated, or set `BUILDARG_KEY` env vars
before the build instead.

## Security note

Every example is designed to be built and run as the invoking user. None
require a root daemon. `apptainer build` writes a single `.sif` file that
is read-only at runtime, signable, and runs under the same UID/GID as
whoever launched it — that's the whole HPC security story from Part 1 of
the deck. See `apptainer-key.md` and `apptainer-key-commands` for the
sign-and-verify workflow.

## See also

- Slide deck: `slides/Current/14-apptainer/14-apptainer.pptx`
- Apptainer user + admin docs: <https://apptainer.org/docs>
- Apptainer signing & verification: <https://apptainer.org/docs/user/latest/signNverify.html>
- NIH-HPC singularity-def-files gallery: <https://github.com/NIH-HPC/singularity-def-files>
- CIQ blog (MPI, OpenFOAM, Slurm integration): <https://ciq.com/blog>
