# Storage Options — Where to Run the Slurm Lab

> **Companion to the Schedulers track.** Read this *before* you start the
> Slurm hands-on lab (`HANDSONLAB.md`) so you know **where on disk to do
> your work**.
>
> The storage track (the labs that run *before* Schedulers) stands up a
> **shared parallel filesystem** mounted at the **same path on the head node
> and both compute nodes**. The Slurm lab is much nicer when you run from
> that shared path: every node sees the same files, so `srun`/`sbatch` can
> `chdir` into your submit directory on the compute nodes and your `.out`/
> `.err` files land where you submitted from — no `couldn't chdir ... going
> to /tmp instead` warnings, no hunting across N VMs for output.
>
> Replace `XX` with your cluster number (e.g. `07`) throughout.

---

## TL;DR — pick the filesystem you built last

Whichever storage lab you ran most recently is the one currently mounted.
Find your row, create the lab work directory once, then use that path
everywhere `HANDSONLAB.md` / `commands` tell you to.

| Storage system | Filesystem | Mounted at (head + compute) | **Slurm lab work dir** |
| -------------- | ---------- | --------------------------- | ---------------------- |
| **Ceph (CephFS)**   | `lci` | `/mnt/cephfs`   | `/mnt/cephfs/projects/slurm-lab`  |
| **BeeGFS**          | —     | `/mnt/beegfs`   | `/mnt/beegfs/scratch/slurm-lab`   |
| **Lustre**          | `lci` | `/lustre/lci`   | `/lustre/lci/scratch/slurm-lab`   |
| **Storage Scale (GPFS)** | `lci` | `/gpfs/lci` | `/gpfs/lci/scratch/slurm-lab`     |

> **Heads up — Ceph is structured differently.** The Ceph lab creates
> `projects/{A,B,C}` (not a `scratch` dir), so the Slurm work dir lives under
> `projects/`. The other three labs create a shared `scratch/`, so the work
> dir lives there.

> **No shared filesystem mounted?** That's fine — the lab also works without
> one. Run job commands from root's home (`cd ~`) on the head node and expect
> the `going to /tmp instead` warning on `srun`. See
> [No shared filesystem (fallback)](#no-shared-filesystem-fallback) below.

---

## One-time setup: create the lab work directory

Do this **once on the head node as root**, after the shared filesystem is
mounted. Pick the block for your filesystem.

The directory is made **world-writable with the sticky bit (`1777`, same as
`/tmp`)**. The Slurm lab submits jobs both as **root** and, in the
exercises, as the eight lab users (`sudo -u bob ...`, `sudo -u justin ...`).
A `1777` work dir lets every one of them write their own `.out`/`.err`
files there while preventing them from deleting each other's — exactly the
`/tmp` model, which is the least-friction choice for the lab.

> Where the lab dir lives depends on how each storage lab lays out its tree.
> BeeGFS, Lustre, and Storage Scale each create a shared `scratch/`, so the
> Slurm lab goes there — transient working space, no quota drama, wiped when
> you re-run the storage lab. Ceph instead creates `projects/{A,B,C}`, so on
> Ceph the lab goes under `projects/`.

### Ceph (CephFS) — `/mnt/cephfs`

The Ceph lab creates `/mnt/cephfs/projects/{A,B,C}` (not a `scratch` dir), so
put the Slurm work dir alongside those projects:

```bash
mkdir -p /mnt/cephfs/projects/slurm-lab
chmod 1777 /mnt/cephfs/projects/slurm-lab
```

CephFS in the storage lab is mounted with `client.admin`, so root can write
freely and `chmod` sticks. Unlike the `projects/{A,B,C}` dirs (which the lab
puts byte/inode quotas on), `slurm-lab` has no quota — fine for the tiny
`.out`/`.err` files this lab produces.

### BeeGFS — `/mnt/beegfs`

```bash
mkdir -p /mnt/beegfs/scratch/slurm-lab
chmod 1777 /mnt/beegfs/scratch/slurm-lab
```

The BeeGFS lab already creates `/mnt/beegfs/home` and `/mnt/beegfs/scratch`.
BeeGFS does not root-squash by default, so root creates and `chmod`s the dir
normally.

### Lustre — `/lustre/lci`

```bash
mkdir -p /lustre/lci/scratch/slurm-lab
chmod 1777 /lustre/lci/scratch/slurm-lab
```

The Lustre lab creates `/lustre/lci/home` and `/lustre/lci/scratch` (with
project IDs and quotas). The `slurm-lab` dir inherits the `scratch` project
ID, so its usage counts against the scratch quota — fine for the small
`.out`/`.err` files this lab produces.

### Storage Scale (GPFS) — `/gpfs/lci`

```bash
mkdir -p /gpfs/lci/scratch/slurm-lab
chmod 1777 /gpfs/lci/scratch/slurm-lab
```

The Storage Scale lab links a `scratch` fileset at `/gpfs/lci/scratch`
(capped at 15 GB total). The `slurm-lab` dir lives inside that fileset.

---

## How to use it in the Slurm lab

Once the work dir exists, **`cd` into it and stay there** for the job-running
parts of the lab. Wherever `HANDSONLAB.md` or `commands` says "run from `~`"
or "create `job.sh`", do it here instead. Set a shell variable so the rest of
the lab reads cleanly:

```bash
# Pick the line matching YOUR filesystem:
export LABDIR=/mnt/cephfs/projects/slurm-lab    # Ceph
# export LABDIR=/mnt/beegfs/scratch/slurm-lab   # BeeGFS
# export LABDIR=/lustre/lci/scratch/slurm-lab   # Lustre
# export LABDIR=/gpfs/lci/scratch/slurm-lab     # Storage Scale

cd "$LABDIR"
```

Then in the lab:

- **Section 5, `srun`** — run `cd "$LABDIR"` instead of `cd ~`. Because the
  path exists identically on the compute nodes, you get **no
  `couldn't chdir ... going to /tmp instead` warning**.
- **Section 5, `sbatch`** — create `job.sh` in `$LABDIR` and `sbatch` it from
  there. `$SLURM_SUBMIT_DIR` will be the shared path, and `test-%j.out` /
  `test-%j.err` are written there — visible from every node.
- **Exercises 1–5 (`sudo -u <user> sbatch ...`)** — run them from `$LABDIR`.
  The `1777` sticky bit lets `bob`, `justin`, `katie`, etc. each write their
  own output. (The load generator uses `-o /dev/null`, so it doesn't depend
  on this — but interactive `sbatch`es in the exercises do.)

### Why this is better than `/tmp` or `~`

- **`~` (root's home)** exists on every node, so `srun`/`sbatch` *work*, but
  `~` is **not shared** — each node has its own. Output written on a compute
  node stays on that compute node; you can't `cat` it from the head.
- **`/tmp`** is where `slurmd` falls back to when your submit dir doesn't
  exist on the compute node. Also per-node and ephemeral.
- **The shared FS** is the same bytes on every node. Submit on the head, read
  the output on the head, even though the job ran on compute. This is how
  real clusters are run, and it's the whole point of having built the
  parallel filesystem in the previous lab.

---

## No shared filesystem (fallback)

If you're running the Slurm lab standalone (no storage lab was run, nothing
mounted), everything still works — just run the job commands from root's home
on the head node:

```bash
cd ~
srun -p lcilab -N2 hostname
```

`srun` will print `error: couldn't chdir to '...': No such file or
directory: going to /tmp instead` if you launch from a head-only path. That's
a **warning, not a failure** — `hostname` doesn't care what directory it runs
in. Launching from `~` keeps the output clean. For `sbatch`, the `.out`/
`.err` files land in whatever directory you submitted from on the head node.

---

## Cleanup

The `slurm-lab` dir is just scratch; it disappears when you tear down the
storage lab. To remove it by hand:

```bash
rm -rf "$LABDIR"            # e.g. /mnt/cephfs/projects/slurm-lab
```

Tearing down the Slurm cluster itself (`./uninstall_all.sh`) does **not**
touch the shared filesystem.
