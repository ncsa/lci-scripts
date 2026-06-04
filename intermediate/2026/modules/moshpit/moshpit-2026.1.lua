-------------------------------------------------------------------------------
-- BLAME: Alan <acchapm1@asu.edu>
-- BUILD_DATE: 2026-05-08
-- BUILD_PATH: /packages/apps/qiime2/moshpit-2026.1
-- CONTAINER:  /packages/apps/simg/moshpit_2026.1.sif
-------------------------------------------------------------------------------

local app_path     = "/packages/apps/qiime2/moshpit-2026.1"
local _name        = "qiime2/moshpit"
local _version     = "2026.1"
local _description = [===[

  MOSHPIT (MOdular SHotgun metagenome Pipelines with Integrated provenance
  Tracking) is a QIIME 2 distribution for whole-metagenome assembly, binning,
  annotation, and analysis.

  This module ships an Apptainer container of MOSHPIT 2026.1. Loading it
  prepends a directory of wrapper scripts to your PATH so that `qiime` and
  `moshpit` invoke the container transparently — no mamba env activation
  required for interactive use.

  Container: /packages/apps/simg/moshpit_2026.1.sif
  Wrappers:  /packages/apps/qiime2/moshpit-2026.1/bin/

  Set up a working dir (copies examples and docs to your scratch) with:
      moshpit-init

  Upstream: https://moshpit.qiime2.org/
]===]

local _help  = string.format([===[

  Name:    %s
  Version: %s
  ## Description ##
  %s
]===], _name, _version, _description)

whatis(_help)
help(_help)

-- All runtime is supplied by the apptainer container, so this module does
-- NOT load mamba/latest or activate any conda env. The wrappers in bin/
-- handle every binding (cwd -> /data, --no-home, etc.) themselves.
prepend_path("PATH", pathJoin(app_path, "bin"))

-- Convenience env vars for users / scripts. MOSHPIT_HOME points at the
-- install root; MOSHPIT_SIF lets the wrappers be overridden against an
-- alternate container image without editing them.
setenv("MOSHPIT_HOME", app_path)
setenv("MOSHPIT_SIF",  "/packages/apps/simg/moshpit_2026.1.sif")

-- moshpit-init: stage examples + docs into the user's scratch dir so they
-- can edit + run without polluting the read-only install path. Re-runs
-- overwrite (refresh examples to current install version).
local scratch_root = "/scratch/$USER/qiime2-moshpit-2026.1"
local init_cmd = table.concat({
    "mkdir -p " .. scratch_root,
    "cp -r " .. pathJoin(app_path, "examples") .. " " .. scratch_root .. "/",
    "cp -r " .. pathJoin(app_path, "docs")     .. " " .. scratch_root .. "/",
    "echo 'Copied examples and docs to " .. scratch_root .. "/'",
}, " && ")
set_alias("moshpit-init", init_cmd)

-- Banner printed on `module load`.
if (mode() == "load") then
    local _loaded = string.format([===[
===============================================================================
Loaded: %s %s

  MOSHPIT is a QIIME 2 distribution for whole-metagenome analysis,
  delivered here as an Apptainer container. After loading, the `qiime`
  and `moshpit` commands are available on your PATH and run transparently
  inside the container.

  First-time setup:
    moshpit-init        # copy example sbatch scripts, parsl configs, and the
                        # user guide to /scratch/$USER/qiime2-moshpit-2026.1/

  Quick reference:
    qiime --help                                    # QIIME 2 CLI
    moshpit info                                    # MOSHPIT q2cli
    cat $MOSHPIT_HOME/docs/user-guide.md            # full user guide

  Note: working files must live under your CWD (mounted into the container
  as /data); paths inside qiime commands should be relative or under the
  CWD. The /scratch/$USER/qiime2-moshpit-2026.1/ workspace satisfies this.
===============================================================================
    ]===], _name, _version)
    LmodMessage(_loaded)
end
