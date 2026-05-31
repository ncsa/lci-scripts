# Spack-generated Apptainer containers

This pair of files demonstrates the Spack workflow shown on slide 18 of
**Module 14 — Apptainer**: declare a software stack in `spack.yaml`,
let Spack generate the Apptainer definition file, then build.

## Files

- **`spack.yaml`** — the input. A small Spack environment listing the
  packages you want (`gcc@12.3.0`, `zlib-ng%gcc@12.3.0`, `7zip`, `tcl`,
  `lua`), the target container format (`singularity`/Apptainer), the
  base image (`rockylinux:8`), and the Spack version to build with
  (`0.22.0`).
- **`gcc.def`** — the output. What `spack containerize` produces from
  `spack.yaml`: a complete Apptainer def file with a `build` stage that
  installs the Spack stack and a `final` stage that copies the install
  tree into a fresh Rocky 8 base. Read it to see what Spack actually
  generates — it's a real-world multistage build.

## How they fit together

```
spack.yaml  ──>  spack containerize  ──>  gcc.def  ──>  apptainer build  ──>  gcc.sif
   ^                                         ^
   |                                         |
   |  (you edit this)                        |  (Spack generated this)
   |                                         |
   `── single source of truth for the entire stack
```

Edit `spack.yaml` to change the packages, the base OS, the Spack version,
or whether to strip binaries. Regenerate `gcc.def` and rebuild — the
container becomes a deterministic product of the yaml. That's the
reproducibility win.

## To rebuild from scratch

```bash
# Activate a Spack environment somewhere that has 'spack containerize':
spack env activate .

# Regenerate the def file:
spack containerize > gcc.def

# Build the image:
apptainer build gcc.sif gcc.def
```

The pre-generated `gcc.def` in this directory is what `spack containerize`
produced on the workshop's reference machine — committed so you can read
it without having to install Spack first.

## What the def file does

Two stages:

1. **`build`** — starts from `spack/rockylinux8:0.22.0` (a Spack base
   image), writes the spack.yaml into the container, runs
   `spack -e . install`, garbage-collects, captures environment changes
   into `environment_modifications.sh`, then strips binaries to shrink
   the final image.
2. **`final`** — starts from a fresh `docker.io/rockylinux:8`, copies
   `/opt/software`, `/opt/views`, and the environment-mods script across
   from `build`, installs `libgfortran` and `wget` for runtime, then
   appends the env mods to `$SINGULARITY_ENVIRONMENT` so they take
   effect at container startup.

End result: a Rocky 8 image with the Spack stack available, **without
Spack itself** in the final layer.

## See also

- Slide deck: `slides/Current/14-apptainer/14-apptainer.pptx` (slide 18)
- Top-level bundle README: `../README.md`
- Spack containers docs: <https://spack.readthedocs.io/en/latest/containers.html>
