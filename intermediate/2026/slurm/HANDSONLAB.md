# Module 12 — Slurm Hands-On Lab

> **`commands` is the source of truth for *what to run*; this file is the
> source of truth for *why*.** Run the commands on your head node
> (`lci-head-XX-1`, where `XX` is your cluster number) as root.
>
> For the install side of things — what `install_all.sh` actually does to
> the cluster, step by step — see `INSTALL.md`.
>
> **Where to run your jobs from:** the storage track (the lab before this
> one) mounts a shared parallel filesystem on every node. Run your
> `srun`/`sbatch` work from there so output is visible cluster-wide. See
> **`Storage-options.md`** for the exact work directory per filesystem
> (Ceph, BeeGFS, Lustre, Storage Scale) and the one-time setup — do that
> before section 5.

## How this lab works

Stand up a working Slurm cluster first, then bend it to five real
complaints: **setup · fairshare · priority · limits · preemption**.

One setup task (install + verify + ClusterShell + users), then five
exercises. Each exercise is framed as a complaint you'd actually get from a
user or PI. The point isn't to memorize commands — it's to feel how
fairshare, priority, and accounting limits interact on a live system.

Lab sections (matching the numbered headers in `commands`):

0. Install the cluster (`install_all.sh`)
1. Verify the install
2. ClusterShell — run commands across many nodes at once
3. Groups and user accounts across all nodes
4. Central logging (rsyslog) on the head node
5. Using the scheduler
6. Exercise 1 — Enabling Fairshare
7. Exercise 2 — Fairshare for Groups AND Users
8. Exercise 3 — Issues with Priority
9. Exercise 4 — Limiting Groups with Accounting
10. Exercise 5 — Preemption for a Low Queue
11. Tear down and re-run

---

## 0. Install the cluster with `install_all.sh`

You have 1 head node and 2 compute nodes. The head node runs `slurmctld`
and `slurmdbd`; the compute nodes run `slurmd`. Clone the bundle on the
head node and run the installer as root:

```bash
git clone https://github.com/ncsa/lci-scripts.git ~/lci-scripts   # skip if already cloned
cd ~/lci-scripts/intermediate/2026/slurm
./install_all.sh XX                # XX = your cluster number, e.g. 07
# or, configless:
./install_all.sh --configless XX   # compute nodes pull slurm.conf from slurmctld
```

`install_all.sh` builds Slurm 25.x from source on the head node, configures
MUNGE and MariaDB, sets up `slurmdbd`, and deploys `slurmd` to the compute
nodes by rsyncing `/opt/slurm` and the MUNGE key. The full walk-through is
in `INSTALL.md`. This replaces the older "follow the Slurm quickstart and
run rpmbuild" path entirely.

**Heads up:** mid-install you'll see a `FAILED!...ignoring` line on a
`mysql -e "SELECT 1 FROM mysql.user ..."` task. **This is normal** — it is
the "does the slurm DB user exist?" check. On a fresh install it doesn't,
so the playbook ignores the failure and creates it in the next task.

### Put the Slurm commands on your PATH

The install writes `/etc/profile.d/slurm.sh`, which prepends
`/opt/slurm/current/bin` to `PATH`. But files in `/etc/profile.d/` are only
sourced by **login** shells — and the root shell that ran `install_all.sh`
was started *before* the install, so it never picked it up. Until you fix
this, `sinfo`, `sacctmgr`, and friends are "command not found" (and
`scripts/create_users_groups.sh` aborts at the Slurm step with
"sacctmgr not found"). Do one of:

```bash
source /etc/profile.d/slurm.sh   # activate in the current shell, now
# or
exit; sudo -i                    # drop root and get a fresh login shell
```

Sourcing your `~/.bashrc` does **not** help — `.bashrc` doesn't read
`/etc/profile.d/`; only the login-shell startup path does.

---

## 1. Verify the install

Before you start configuring, confirm the installer left you with a working
cluster. Three classes of problem show up here and all of them snowball if
you push past:

```bash
systemctl status mariadb
systemctl status slurmctld
systemctl status slurmdbd
timedatectl status
sinfo
ssh lci-compute-XX-1 systemctl status slurmd
```

What "working" looks like:

- **`mariadb`, `slurmctld`, `slurmdbd`** all `active (running)` on the head
  node. `slurmdbd` listens on port 6819, `slurmctld` on 6817. These two
  must be up *before* `slurmd` will talk to the cluster.
- **`timedatectl status`** shows `System clock synchronized: yes`. MUNGE
  credentials carry a timestamp and will be rejected if any two nodes are
  more than a few minutes apart, so a desynced clock shows up later as
  "Invalid credential" errors that look unrelated. Catch it here.
- **`sinfo`** shows both compute nodes in state `idle` under the `lcilab`
  partition. If they're `down*` or `drain`, `slurmctld` can't reach
  `slurmd` — almost always either MUNGE, a `.novalocal` hostname mismatch
  (see section 2), or `slurmd` not started.
- **`ssh lci-compute-XX-1 systemctl status slurmd`** shows
  `active (running)` on each compute node.

If you used `--configless`, also confirm:

```bash
ssh lci-compute-XX-1 ls -l /etc/slurm/slurm.conf   # No such file or directory
ssh lci-compute-XX-1 scontrol show config | head   # served by controller
```

In configless mode the compute nodes do not have a local
`/etc/slurm/slurm.conf`; `slurmd` was launched with
`--conf-server $SLURMCTLD_HOST` and pulled the config from `slurmctld` at
startup. `scontrol show config` proves the running config is the
controller's, not a stale local file. See `INSTALL.md` section 6 for the
full classic-vs-configless story.

---

## 2. ClusterShell — run commands across many nodes at once

ClusterShell's `clush` lets you fan one command out across a named group of
nodes. The rest of the lab uses `clush -g compute "..."` constantly, so we
set it up first. (This deck replaces the older `pdsh` instructions.)

```bash
dnf install -y clustershell
```

Then teach `clush` what "compute" means. Edit
`/etc/clustershell/groups.d/local.cfg`, remove the example content that
ships uncommented, and add (with your cluster number):

```
head: lci-head-XX-1
compute: lci-compute-XX-[1-2]
login: lci-head-XX-1
storage: lci-storage-XX-[1-4]
```

The `[1-2]` is `clush`'s native range syntax — it expands to
`lci-compute-XX-1,lci-compute-XX-2`. The `login:` group is the same host as
`head:`; it's there because some `clush` config recipes expect a login
group, and giving it the head's name is a no-op. The `storage:` group covers
the four storage nodes (`lci-storage-XX-1` through `lci-storage-XX-4`) — the
storage track's BeeGFS install drives them from the head node with
`clush -g storage`.

Verify:

```bash
clush -g compute "uptime"
```

You should see two lines, one per compute node. If `clush` complains about
the group not existing, the config file path is wrong or the file has stray
content — re-check `/etc/clustershell/groups.d/local.cfg`.

### Why the hostname-fix line exists

The compute VMs are provisioned by cloud-init, which often leaves the
kernel hostname as `lci-compute-XX-1.novalocal` instead of the bare
`lci-compute-XX-1`. Slurm's `NodeName` in `slurm.conf` is the bare form,
and `slurmd` registers under `gethostname()` — so
the mismatch makes `slurmctld` think the node is unreachable even though
`slurmd` is happily running.

The fix is one line of `clush`:

```bash
clush -g compute 'correct_hostname=$(grep $(hostname -s) /etc/hosts | grep lci-compute | head -1 | awk "{print \$2}"); sudo hostnamectl set-hostname $correct_hostname'
```

What it does on each compute node, left-to-right:

1. `hostname -s` — current short hostname (e.g. `lci-compute-07-1` or
   `lci-compute-07-1.novalocal` depending on what cloud-init set).
2. `grep $(hostname -s) /etc/hosts` — find the matching line in
   `/etc/hosts` (which the playbook seeded with the canonical name).
3. `grep lci-compute` — keep only the lci-compute line (filters out any
   `localhost` matches).
4. `head -1 | awk '{print $2}'` — first match, second column. In
   `/etc/hosts` that's the canonical name (e.g. `lci-compute-07-1`).
5. `hostnamectl set-hostname ...` — set the live hostname to that.

After this, `hostname` returns the bare name on each compute node, matching
what `slurm.conf` expects.

---

## 3. Groups and user accounts across all nodes

The exercises in sections 6–10 cast eight users in four departments. The
lab uses Linux groups and Linux users for the OS side (so jobs actually run
as a real user), plus Slurm accounts and association records for the
scheduler side (so accounting, fairshare, and limits have something to
apply against).

```
Department   Group     GID    Users (UID)
biology      lci-bio   3001   bob   (2002), alice (2003)
engineering  lci-eng   3002   justin(2004), katie (2005)
chemistry    lci-chem  3003   carol (2006), dave  (2007)
physics      lci-phys  3004   erin  (2008), frank (2009)
```

### Why pinned UIDs/GIDs

Every UID and GID is explicit. Two reasons:

1. **Consistency across nodes.** A job submitted as `bob` on the head node
   runs as UID 2002 on the compute node. If `useradd` on the compute node
   had picked a different UID, jobs would still "work" under MUNGE auth but
   file ownership on any shared filesystem (the Chosen Storage Solution
   from the previous lab, or `/tmp`
   job containers here) would be a mess. Pinning the UID guarantees the
   user is the *same* user everywhere.
2. **Determinism for the exercises.** The exercises hard-code things like
   "bob's reservation" and refer to users by name. If you re-run the lab
   from scratch, you want the same user/account mapping every time.

The GID range (3001–3004) is intentionally below the typical user GID range
to keep these as "department" groups, distinct from auto-created per-user
groups.

### Shortcut

The full section is also baked into `scripts/create_users_groups.sh` as an
idempotent shell script — Linux groups + users on head and compute, plus
the matching Slurm accounts. Re-runnable safely. Run it instead of typing
the commands by hand:

```bash
./scripts/create_users_groups.sh
```

The hand-typed commands in `commands` are kept so you can see what the
script does and pull out individual pieces.

### The Slurm accounting tree

```bash
sacctmgr -i add account biology     Description="Biology dept"     Organization=lci
sacctmgr -i add account engineering ...
sacctmgr -i add user bob    Account=biology     DefaultAccount=biology
...
```

These build the Slurm-side mirror of the OS groups. Why this exists:
`slurm.conf` is configured with `AccountingStorageEnforce=limits,qos`,
which means `slurmctld` **refuses to run jobs** under an OS user that
doesn't have a matching Slurm association. Without this section, every
`sbatch` would fail with something like "Invalid account or
account/partition combination specified."

`DefaultAccount=` is what lets users in the exercises run
`sbatch -p lcilab -n1 --wrap "sleep ..."` without saying `--account=biology`
every time.

Verify with:

```bash
sacctmgr show account
sacctmgr show assoc format=Account,User,Share,QOS
```

The second command shows the full association tree (root → account → user)
that the fairshare and limits exercises will manipulate.

---

## 4. Central logging (rsyslog) on the head node

This section turns the head node into a syslog collector and points every
compute node at it. After this, all syslog from every node ends up in
`/var/log/<hostname>/forwarded-logs.log` on the head.

This is real-cluster practice — when a job mysteriously fails on compute,
you want the logs in one place, not scattered across N ephemeral VMs.

### Head node — receive

Edit `/etc/rsyslog.conf` and **uncomment** these four lines (they ship
commented in Rocky 9):

```
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")
```

That opens UDP/514 and TCP/514 so other rsyslogs can forward into this one.
UDP is the historical default (lossy but cheap); TCP is modern. We enable
both because compute nodes default to UDP.

Then at the end of the `### Modules ###` section, add:

```
$template DynamicFile,"/var/log/%HOSTNAME%/forwarded-logs.log"
*.* -?DynamicFile
```

Two things going on:

- `$template DynamicFile, "..."` defines a *dynamic* path template where
  `%HOSTNAME%` is filled in from each incoming log record's hostname field.
  So messages from `lci-compute-XX-1` land in
  `/var/log/lci-compute-XX-1/forwarded-logs.log`, messages from
  `lci-compute-XX-2` in `/var/log/lci-compute-XX-2/...`, etc.
- `*.* -?DynamicFile` says "every facility, every priority — write to the
  file defined by the `DynamicFile` template." The `?` makes it dynamic.
  The leading `-` means "don't fsync on every write" — syslog is
  high-volume; the small risk of losing the last few messages on a crash is
  worth the throughput.

Restart so the listener comes up:

```bash
systemctl restart rsyslog
```

### Compute nodes — forward

Add to the bottom of `/etc/rsyslog.conf` on each compute node:

```
*.* @lci-head-XX-1
```

Single `@` = UDP, double `@@` = TCP. UDP is fine for a lab. Then:

```bash
clush -g compute "systemctl restart rsyslog"
```

### Verify

```bash
ls /var/log/lci-compute-XX-*/
```

You should see one directory per compute node, each containing a
`forwarded-logs.log`. If the directories don't appear, either the listener
didn't come up (check `ss -lntu | grep 514` on the head), the compute nodes
can't reach the head on 514 (firewall?), or the forward directive on
compute is wrong.

---

## 5. Using the scheduler

This is the baseline "is the cluster doing anything useful" check. None of
these change configuration; they just exercise what's already installed.

### `sinfo` — partitions and node state

```bash
sinfo
sinfo -N -l
```

`sinfo` summarizes by partition (one line per partition × state
combination). `sinfo -N -l` is the long, per-node view — gives you state,
reason for drain (if any), CPUs, memory, features. When something is wrong
with a node, `-N -l` is the first thing to run.

State legend you'll actually see:

- `idle`   — node is up, no jobs running, available
- `alloc`  — fully allocated to jobs
- `mix`    — partially allocated
- `down`   — `slurmctld` declared it down (often = `slurmd` unreachable)
- `drain`  — administratively unavailable; ongoing jobs finish, no new ones
- `drng`   — draining (still has running jobs)
- A trailing `*` means the controller has not heard from `slurmd` recently.
  `down*` is the configless-and-MUNGE-troubleshooting canonical state.

### `srun` — interactive run

**First, set up your work directory.** Before running anything here, make
sure you've done the one-time setup in `Storage-options.md` for whichever
shared filesystem the storage lab left mounted, and point `LABDIR` at it:

```bash
export LABDIR=/mnt/cephfs/projects/slurm-lab   # Ceph — adjust per Storage-options.md
mkdir -p "$LABDIR"
cd "$LABDIR"
srun -p lcilab -N2 hostname
```

`-N2` means "give me 2 nodes." `srun` allocates them, runs `hostname` once
per node, prints the output, and exits. This is the cheapest way to confirm
jobs actually launch on the compute nodes.

**Why launch from the shared work dir.** `srun` tries to start the remote
task in the same working directory you launched from. The shared filesystem
(`Storage-options.md`) is mounted at the **same path on every node**, so when
you launch from `$LABDIR` the compute nodes can `chdir` into it cleanly — no
warning, and any output lands somewhere all nodes can see.

If you launch from a path that exists *only* on the head node — e.g.
`~/lci-scripts/intermediate/2026/slurm` — `slurmd` on each compute node
prints `error: couldn't chdir to '...': No such file or directory: going to
/tmp instead` and falls back to `/tmp`. It's a **warning, not a failure** —
`hostname` doesn't care what directory it runs in.

**No shared filesystem mounted?** Run from `~` instead (`cd ~`); root has a
home on every node, so jobs run fine — output just isn't shared across nodes.
See the fallback section in `Storage-options.md`.

**Why `-p lcilab` is required.** The `lcilab` partition is defined
`Default=No` in `slurm.conf`, so there is no *system default* partition.
Any job that omits `-p` — `srun -N2 hostname` on its own — fails with
`srun: error: Unable to allocate resources: No partition specified or
system default partition`. That's why every job command in this lab names
its partition explicitly. (If you'd rather make `lcilab` the default,
change `Default=No` to `Default=YES` in `/etc/slurm/slurm.conf` and re-run
`scontrol reconfigure` — but the lab keeps it explicit on purpose.)

### `sbatch` — batch submission

Create and submit this from your shared work dir (`cd "$LABDIR"` — see
`Storage-options.md`) so `$SLURM_SUBMIT_DIR` is the shared path and the
`test-%j.out` / `test-%j.err` files land where every node can read them.

A minimal job script `job.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=test
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --partition=lcilab
#SBATCH --output=test-%j.out
#SBATCH --error=test-%j.err
echo "Job $SLURM_JOB_ID running on $SLURM_JOB_NODELIST"
echo "Submitted from: $SLURM_SUBMIT_DIR"
echo "--- one line per node (hostname + date): ---"
srun bash -c 'echo "$(hostname) reporting at $(date)"'
```

`#SBATCH` directives are equivalent to `sbatch` command-line flags.

The `--output`/`--error` directives are the point of this example. This job
runs in a fraction of a second and prints to files, not your terminal — so
without somewhere to send stdout/stderr there is **nothing to look at and no
way to tell the job worked**. `%j` expands to the job ID, so each run gets
its own `test-<jobid>.out` / `test-<jobid>.err` instead of overwriting the
last.

The body is split deliberately:

- The three `echo` lines run **in the batch script itself**, on the first
  allocated node. Their stdout goes straight to the batch script's
  `--output` file, so you are *guaranteed* visible content — job ID, the
  node list Slurm gave you, and where you submitted from.
- The `srun` line launches a **job step** that fans out across the
  allocation — one task per node — so you see *both* compute nodes report
  in, each with its own hostname and timestamp. Running work as a step is
  also what makes it show up in `sacct` later.

Why not just `srun hostname`? With this cluster's `TaskPlugin=task/cgroup`
and `JobContainerType=job_container/tmpfs`, step stdout doesn't always make
it back into the batch script's `--output` file — which is exactly why a
bare `srun hostname` can leave you with an empty `.out` and nothing to
verify. The batch-level `echo`s sidestep that: they always land in the file.

```bash
sbatch job.sh
```

Returns a job ID. Once it's done (a second or two — `squeue` will show it
gone), confirm it actually ran:

```bash
cat test-*.out                  # job ID, nodelist, one line per compute node
cat test-*.err                  # empty on success
```

A populated `test-<jobid>.out` — with the job ID, the nodelist, and a
`reporting at` line from each compute node — is your proof the job ran and
landed on both nodes. (Without an explicit `--output`, Slurm defaults to
`slurm-<jobid>.out` in the submit directory — but naming it yourself makes
the file easy to find and shows the directive that controls it.)

### Inspecting jobs

```bash
squeue                          # what's in the queue / running
scontrol show nodes             # full node detail (use to debug down/drain)
scontrol show partition         # partition detail (limits, allowed accounts)
sacct                           # historical jobs from slurmdbd
```

`squeue` is the live view. `sacct` is the post-mortem — it reads from
`slurmdbd`/MariaDB and shows jobs that have already finished (plus current
jobs).

---

## A note on the exercises (sections 6–10)

These tune the *running* scheduler so you can watch behavior change
immediately. Two ways to apply a change:

1. **Edit `/etc/slurm/slurm.conf` on the head** and run
   `scontrol reconfigure`. This is for things controlled by `slurm.conf`:
   scheduler tuning, priority, partitions, QOS assignments at the partition
   level.
2. **`sacctmgr` / `scontrol create ...`**. These talk to `slurmdbd`
   (accounting tree, QOS definitions, reservations). They take effect
   immediately — no `reconfigure` needed.

**Live edits to `slurm.conf` are lost on the next playbook re-run** — the
installer rewrites the file. For this lab that's fine: the exercises tune the
*running* scheduler and you re-run the install clean when you're done.

The shipped `slurm.conf` already has the machinery the exercises
rely on — you only edit per-exercise tuning, not these:

```
SlurmctldParameters=enable_configless          # configless ready
SelectType=select/cons_tres                    # fine-grained allocation
SchedulerType=sched/backfill                   # backfill scheduler
PriorityType=priority/multifactor              # required for fairshare
PriorityWeightFairshare/Age/QOS/...            # weights pre-set
PreemptType=preempt/qos, PreemptMode=CANCEL    # for exercise 5
AccountingStorageEnforce=limits,qos            # for exercises 4 and 5
ProctrackType=proctrack/cgroup
JobContainerType=job_container/tmpfs
TaskPlugin=task/cgroup,task/affinity
```

### The load generator

Most exercises drop traffic on the queue with a reusable script — it lives
in the bundle as `scripts/load.sh` and is used in exercises 1, 2, and 5.
Install it once on the head node, then call it freely:

```bash
cd ~/lci-scripts/intermediate/2026/slurm/
cp scripts/load.sh /root/load.sh && chmod +x /root/load.sh
# usage: /root/load.sh USER COUNT [PARTITION] [QOS]
```

What's inside (7 lines):

```bash
#!/bin/bash
u=$1; n=$2; part=${3:-lcilab}; qos=${4:-normal}
# Resolve sbatch to its absolute path: sudo's secure_path does not include
# /opt/slurm/current/bin, so a bare `sudo -u "$u" sbatch` fails with
# "command not found".
sbatch=$(command -v sbatch || echo /opt/slurm/current/bin/sbatch)
for i in $(seq 1 "$n"); do
  sudo -u "$u" "$sbatch" -p "$part" -q "$qos" -n1 \
    --wrap "sleep 600" -J "${u}-${i}" -o /dev/null
done
```

It submits N 10-minute `sleep` jobs as the named user, each requesting one
core. The 10-minute duration is long enough to see scheduling behavior; the
single-core size guarantees jobs are unit-allocatable so the queue actually
backs up.

> **Why the absolute path to `sbatch`?** Slurm's PATH entry
> (`/etc/profile.d/slurm.sh`) is only sourced by **login** shells, and `sudo`
> additionally sanitizes `PATH` to its compiled-in `secure_path`
> (`/sbin:/bin:/usr/sbin:/usr/bin`) — which does *not* include
> `/opt/slurm/current/bin`. So a bare `sudo -u bob sbatch ...` fails with
> `sbatch: command not found`, even though `sbatch` works fine in your root
> shell. Every `sudo -u … sbatch` in the exercises below uses the full path
> `/opt/slurm/current/bin/sbatch` for the same reason.

Each user already has a `DefaultAccount` from section 3, so the script
doesn't need `--account=`. `-o /dev/null` discards the stdout files
(otherwise running 15 of these spams the cwd).

---

## 6. Exercise 1 — Enabling Fairshare

**Complaint.** Professor Bob runs a few 4-core jobs a week. Justin's lab
flat-out hammers the cluster with single-core jobs and crowds Bob out.

**Goal.** Give every user an equal fairshare slot at the queue and tune
the decay so the system reacts within minutes (the default ~week is useless
for a live demo).

### Prerequisites

Before starting this exercise confirm:

- Section 3 is complete — the eight users and four Slurm accounts (`biology`,
  `engineering`, `chemistry`, `physics`) exist.
- `scripts/load.sh` has been staged on the head node (one-time setup from
  the load generator section above):

  ```bash
  cp scripts/load.sh /root/load.sh && chmod +x /root/load.sh
  ```

- You are running commands on the head node (`lci-head-XX-1`) as root with
  `/opt/slurm/current/bin` on your `PATH`.

### The three knobs you set in `slurm.conf`

Edit `/etc/slurm/slurm.conf` on the head node and set (or update) these
three parameters:

```
PriorityDecayHalfLife=00:10:00
PriorityCalcPeriod=00:01:00
FairShareDampeningFactor=1
```

- `PriorityDecayHalfLife=00:10:00` — Past usage decays with a 10-minute
  half-life. After 10 minutes, a unit of usage counts half as much; after
  20 minutes, a quarter. The production default is on the order of a week
  (`7-0`); cranking it to 10 minutes means Justin's queue flood will start
  penalising him visibly inside the lab session.
- `PriorityCalcPeriod=00:01:00` — Recalculate priorities every minute.
  The default is 5 minutes. Tightening this to 1 minute means `sprio -l`
  output changes while you are watching rather than after you have moved on.
- `FairShareDampeningFactor=1` — Controls how aggressively the fairshare
  factor differentiates between different levels of overuse. A value of `1`
  gives a roughly linear response — the difference between consuming 10× your
  share and 100× your share is clearly visible in `sprio`. Higher values
  (up to 10) amplify that gap further. The system default is `1`; being
  explicit here documents intent and makes it easy to experiment with
  during the session. Keep `PriorityFlags=DEPTH_OBLIVIOUS` commented out
  — turning that on collapses the hierarchical depth calculation and
  changes the fairshare scores.

> **Note.** The shipped `slurm.conf` already includes
> `PriorityType=priority/multifactor` and the base `PriorityWeight*`
> settings. You are tuning the decay and dampening on top of that
> foundation — not replacing it.

Apply live:

```bash
scontrol reconfigure
```

No daemon restart required. `scontrol reconfigure` signals `slurmctld` to
re-read `slurm.conf` and immediately applies priority parameter changes.

### Equal shares for all accounts

```bash
sacctmgr -i modify account where name=biology     set fairshare=1
sacctmgr -i modify account where name=engineering set fairshare=1
sacctmgr -i modify account where name=chemistry   set fairshare=1
sacctmgr -i modify account where name=physics     set fairshare=1
```

`fairshare=1` per account = each department's *share* of the cluster is
identical at the account level. Users inherit equal shares by default
underneath that, so individual users in different departments also get
equal weight.

### Verify

```bash
sshare -l                # per-association Level FS and effective shares
sshare -a -l             # also include users; you can count the levels
scontrol show config | grep -iE \
  'PriorityDecayHalfLife|PriorityCalcPeriod|FairShareDampeningFactor|PriorityFlags'
```

`sshare` is the canonical fairshare inspection tool. `-l` switches to the
long view with "Level FS" — that's the per-level fairshare factor, the
number the priority calculation actually consumes.

**What to look for in `sshare -l`:** Four account rows with `RawShares=1`
and identical `NormShares` (roughly 0.25 each). `EffectvUsage` will be
`0.000000` for everyone at rest; `FairShare` will show `1.000000` for all
associations — perfect equity at baseline.

**What to look for in `scontrol show config`:**

```
FairShareDampeningFactor = 1
PriorityDecayHalfLife    = 00:10:00
PriorityCalcPeriod       = 00:01:00
PriorityFlags            =
```

The empty `PriorityFlags =` line (nothing after the `=`) is the proof that
`DEPTH_OBLIVIOUS` is **not** set — exactly what Exercises 1 and 2 need. If
you instead see `PriorityFlags = DEPTH_OBLIVIOUS`, the hierarchical fairshare
depth is collapsed; comment that line out in `slurm.conf` and re-run
`scontrol reconfigure`. Likewise, if `PriorityDecayHalfLife` still shows the
old default, the reconfigure may not have picked up the file — double-check
the edit and re-run.

### Drive it

```bash
/root/load.sh justin 15
/root/load.sh bob 3
sleep 60
sprio -l
sshare -a
squeue -o "%.8i %.9P %.8u %.10Q %R"
```

`justin` has 15 jobs pending; `bob` has 3. With fairshare on, `bob`'s jobs
should land with a higher priority than `justin`'s because Justin's recent
usage is climbing fast while Bob's stays low. `sprio -l` shows the fairshare
*component* of each job's priority; `sshare -a` shows each user's effective
usage. `squeue` ordered by `%Q` (priority) makes the result visible at a
glance.

**What you should see:** In `sprio -l`, Bob's jobs show a noticeably higher
`FAIRSHARE` component. In `sshare -a`, Justin's `EffectvUsage` is climbing
while Bob's stays near zero; Justin's `FairShare` score drops below 0.5,
Bob's stays near 1.0. The exact numbers depend on how fast you ran the load
— give it 60 seconds and re-run `sprio -l` to see the values move.

> **Tip.** To reset between runs: `scancel -u justin; scancel -u bob`
> Usage history persists in `slurmdbd` and decays naturally. For a
> clean-slate baseline, zero the raw usage counters:
> ```bash
> sacctmgr -i modify account where name=biology,engineering,chemistry,physics \
>   set RawUsage=0
> ```

---

## 7. Exercise 2 — Fairshare for Groups AND Users

**Setup.** Departments share the cluster evenly with each other, AND users
share evenly *inside* their department. This is hierarchical fairshare: the
algorithm applies shares at the account level AND the user level.

The account-level shares are already 1 each from exercise 1. Now make
user-level shares explicit:

```bash
sacctmgr -i modify account where name=biology,engineering,chemistry,physics \
  set fairshare=1
sacctmgr -i modify user bob    set fairshare=1
sacctmgr -i modify user alice  set fairshare=1
sacctmgr -i modify user justin set fairshare=1
sacctmgr -i modify user katie  set fairshare=1
sacctmgr -i modify user carol  set fairshare=1
sacctmgr -i modify user dave   set fairshare=1
sacctmgr -i modify user erin   set fairshare=1
sacctmgr -i modify user frank  set fairshare=1
```

> **Note on the `where` clause.** When modifying accounts by name, use
> `where name=`. Using `where account=` filters by *parent account*, not
> account name, and will silently match nothing at the top level of the
> hierarchy.

Inspect:

```bash
sshare -l
```

You'll see the tree: root, then the four accounts at the same level under
root, then users underneath each account, all with `RawShares=1`.

### Why this matters — observe katie

```bash
/root/load.sh justin 15      # engineering over-uses
sleep 60
sshare -a                    # katie's share drops too (same account)
sprio -l
```

Watch `katie`. She personally hasn't submitted anything. But the
*engineering account* (her account) has been consuming the cluster hard via
Justin, so Katie's *effective* share drops. That's hierarchical fairshare
working: the account's overuse penalizes every user inside the account, not
just the user who did the overusing.

If shares were flat (no hierarchy), Katie would be unaffected by Justin's
flood and would simply elbow in front of every other engineering user.
Hierarchical is the model real-world clusters use because it gives groups a
budget to police themselves.

---

## 8. Exercise 3 — Issues with Priority

**Complaint.** Bob is back — paper deadline, and he can't get high-priority
jobs through even with fairshare on. Two fixes:

- (a) a 20-minute reservation on a node just for Bob (temporary)
- (b) a permanent higher-priority partition

### (a) Reservation

> Replace `XX` with your cluster number in `Nodes=lci-compute-XX-1`.

```bash
scontrol create reservation \
  ReservationName=bob_deadline \
  StartTime=now Duration=00:20:00 \
  Users=bob \
  Nodes=lci-compute-XX-1
scontrol show reservation
sudo -u bob /opt/slurm/current/bin/sbatch --reservation=bob_deadline -p lcilab -n1 -o /dev/null -e /dev/null --wrap "sleep 300"
```

A reservation is a chunk of resources marked off for specific users during
a specific window. `Users=bob` means only Bob can submit into it.
`Nodes=lci-compute-XX-1` reserves the whole node. Bob has to ask for it
explicitly: `sbatch --reservation=bob_deadline ...`.

> **Why `-o /dev/null -e /dev/null`?** The job inherits *your* (root's)
> current directory, and `sbatch` defaults to writing `slurm-<jobid>.out`
> there. But the job runs as `bob`, and `bob` can't create a file in `/root`
> (mode 700) or a root-owned `$LABDIR` — so `slurmd` kills the job the instant
> it starts: it shows up as `FAILED`, exit code 15, dead in ~1 second with 0
> CPU used (exactly what `seff` reports). Discarding stdout/stderr to
> `/dev/null` sidesteps the problem — the same trick `scripts/load.sh` uses.
> You observe these demo jobs through `squeue`/`sacct`/`sprio`, not their
> output, so there's nothing to lose. (Alternatively, point `-o`/`-e` at a
> directory `bob` *can* write, e.g. `-o /tmp/bob-%j.out`.) Every
> `sudo -u … sbatch` in this exercise and the next two does the same.

This is the cluster admin's "I owe you" — it cuts the line for a named user
without changing the scheduler's permanent policy. Surgical and temporary.

### (b) High-priority partition

Add to `/etc/slurm/slurm.conf`:

```
PartitionName=high Nodes=lci-compute-XX-[1-2] Default=No \
  PriorityTier=100 QOS=normal AllowQOS=normal
```

`PriorityTier` is the partition-level priority knob. **A partition with a
higher tier jumps the queue over partitions with a lower tier — no matter
the per-job priority.** The default `lcilab` partition is `PriorityTier=1`;
this `high` partition is `PriorityTier=100`. Any pending job in `high` will
be scheduled before any pending job in `lcilab`, period. Powerful and easy
to abuse — which is exactly what exercise 4 punishes.

`QOS=normal AllowQOS=normal` keeps the QOS and accounting rules consistent
with `lcilab` — you don't get higher fairshare weight here, you just get to
skip the line.

Apply with `scontrol reconfigure`, then prove it:

```bash
scontrol reconfigure
sinfo -o "%.12P %.5a %.10l %.6D"     # confirm 'high' exists
sudo -u bob    /opt/slurm/current/bin/sbatch -p high   -n1 -o /dev/null -e /dev/null --wrap "sleep 300"
sudo -u justin /opt/slurm/current/bin/sbatch -p lcilab -n1 -o /dev/null -e /dev/null --wrap "sleep 300"
squeue -o "%.8i %.9P %.8u %.10Q %R"
```

**What you should see:** Bob's job (in `high`) starts before Justin's (in
`lcilab`) even if both are submitted in the opposite order — that's the tier
doing its job.

---

## 9. Exercise 4 — Limiting Groups with Accounting

**Setup.** IT sells resources per department. Cap each department at 20
CPU-hours (= 1200 CPU-minutes), and make the `high` partition cost twice as
much as `lcilab`.

### CPU-time cap via `GrpTRESMins`

```bash
sacctmgr -i modify account where name=biology     set GrpTRESMins=cpu=1200
sacctmgr -i modify account where name=engineering set GrpTRESMins=cpu=1200
sacctmgr -i modify account where name=chemistry   set GrpTRESMins=cpu=1200
sacctmgr -i modify account where name=physics     set GrpTRESMins=cpu=1200
sacctmgr show assoc format=Account,User,GrpTRESMins
```

`GrpTRESMins` is the cumulative cap on a TRES (Trackable RESource).
`cpu=1200` = 1200 CPU-minutes = 20 CPU-hours. It's enforced because
`slurm.conf` has `AccountingStorageEnforce=limits,qos`. When a department
hits its cap, new jobs from that account stop running and pend with
`Reason=GrpTRESMins`.

This is *not* a rate limit — it's a meter. Usage accumulates over time and
counts toward the cap.

### Differential billing via `TRESBillingWeights`

Make `high` cost 2× normal. Edit `/etc/slurm/slurm.conf` and give `high`
its own line (`lcilab` keeps the default `CPU=1.0`):

```
PartitionName=high ... TRESBillingWeights="CPU=2.0,Mem=.25G,gres/gpu=3.0"
```

`TRESBillingWeights` is a per-partition multiplier on how usage is *billed*
against the account's cap. `CPU=2.0` on `high` means one CPU-minute of wall
time on the high partition is billed as two CPU-minutes against
`GrpTRESMins`. The `lcilab` partition keeps the default `CPU=1.0`.

So a 60-minute, one-CPU job:

- On `lcilab`: bills 60 CPU-minutes.
- On `high`: bills 120 CPU-minutes — the natural disincentive against
  camping on the fast lane.

The `Mem=.25G` and `gres/gpu=3.0` entries are there to show the syntax —
even though this lab doesn't actually use them, the format is
`KEY=WEIGHT[,KEY=WEIGHT,...]`.

### Demo and verify

```bash
scontrol reconfigure
sudo -u carol /opt/slurm/current/bin/sbatch -p lcilab -n2 -o /dev/null -e /dev/null --wrap "sleep 600"   # chemistry
sleep 60
sacct -X -a --starttime=$(date +%Y-%m-%d) --format=JobID,User,Account,State,Elapsed,AllocCPUS,CPUTimeRAW
squeue -o "%.8i %.9P %.8u %.8a %R"
```

`sacct -X` reads the per-job records straight from `slurmdbd`, so each job's
consumption is visible the moment it finishes — no waiting on a rollup.
`CPUTimeRAW` is CPU-seconds (`AllocCPUS` × `Elapsed`); that's the usage that
accumulates against the account's `GrpTRESMins` cap (divide by 60 for the
CPU-minutes the cap is expressed in). The `squeue` line at the end exposes
the `Reason` column (`%R`) — that's where you see `GrpTRESMins` once an
account hits its cap. (`sreport cluster AccountUtilizationByUser` gives the
same numbers aggregated per account, but it reads `slurmdbd`'s hourly
rolled-up tables, so right after a short demo it's typically empty.)

---

## 10. Exercise 5 — Preemption for a Low Queue

**Setup.** Offer a low-priority queue ("low") that:

- only ever backfills (never displaces a normal job),
- gets *preempted* (killed) by normal jobs that need its resources,
- is billed at half cost.

This is the classic "scavenger" or "spot" queue — cheap, takes whatever's
left, gets evicted when real work shows up. `PreemptType=preempt/qos` and
`PreemptMode=CANCEL` are already set in the shipped `slurm.conf`.

### Configure the QOS

Create the `low` QOS and set its billing and priority properties:

```bash
sacctmgr -i add qos low Priority=0 UsageFactor=0.5
```

- `Priority=0` — last in line for scheduling.
- `UsageFactor=0.5` — billed at half rate against `GrpTRESMins`. 10
  wall-minutes of one CPU bills as 5 CPU-minutes.

> **Note.** When using `sacctmgr add qos`, key=value pairs follow the QOS
> name directly — no `set` keyword. `set` is only used with `modify`.
> `Preempt` and `Flags` default to empty on a new QOS and do not need to
> be explicitly specified.

Then declare which QOS preempts which:

```bash
sacctmgr -i modify qos normal set Preempt=low
```

`normal` preempts `low`. Because `slurm.conf` has `PreemptMode=CANCEL`,
"preempt" means "cancel the low job to free up the resources for a normal
job." `CANCEL` is the simplest preemption mode for a demo. Production
scavenger queues usually use `REQUEUE` so the displaced job ends up back in
the queue instead of dying outright; `SUSPEND` and `GANG` are the other
options — discuss the trade-offs.

Finally, grant `low` to each department's association. A new QOS exists
cluster-wide, but with `AccountingStorageEnforce=limits,qos` a user can only
submit under a QOS that's in their **association's** allowed QOS list — which
defaults to just `normal`. Add `low` to all four accounts (`+=` appends to
the existing list rather than replacing it):

```bash
sacctmgr -i modify account where name=biology,engineering,chemistry,physics \
  set qos+=low
```

> **Note.** This is a *separate* check from the partition's `AllowQOS`
> (configured in the next step). Both must permit `low`, or `sbatch -q low`
> fails with `Invalid qos specification`. Skip this grant and even a correctly
> configured partition rejects the job, because bob's association still only
> allows `normal`.

### Allow it on the partition

`AllowQOS` lists which QOSes can land on this partition. Without adding
`low`, users can `sbatch -q low` all they want and slurmctld will refuse it
with "Invalid qos". Edit `/etc/slurm/slurm.conf`:

```
PartitionName=lcilab ... QOS=normal AllowQOS=normal,low
```

```bash
scontrol reconfigure
sacctmgr show qos format=Name,Priority,UsageFactor,Preempt
```

### Demo

```bash
/root/load.sh justin 4                  # fills both 2-CPU nodes (normal)
sudo -u bob /opt/slurm/current/bin/sbatch -p lcilab -q low -n1 -o /dev/null -e /dev/null --wrap "sleep 600"
squeue -o "%.8i %.9P %.8u %.6q %.10Q %.15R"   # %q = QOS
sacct -X -a --starttime=$(date +%Y-%m-%d) --format=JobID,User,Account,State,Elapsed,AllocCPUS,CPUTimeRAW
```

The cluster has 2 nodes × 2 CPUs = 4 CPU slots. The 4 normal-QOS jobs from
Justin fill it. Bob's `-q low` job pends with `Reason=Resources`. Now
cancel one of Justin's jobs and verify Bob's job starts. 

```bash
squeue   #note a jobid from Justin
scancel 50 # assuming 50 is the jobid of one of Justin's running jobs
squeue   # verify Bob's low qos job has started
/root/load.sh justin 1
squeue   # Bobs job is gone as the new Justin job on the normal qos preempted it. 
```

**What you should see:** Bob's low-QOS job pends immediately with
`Reason=Resources`. After cancelling a Justin job (`scancel <jobid>`), Bob's
job starts. If instead you let a normal job arrive while Bob's low job is
running, Bob's job transitions to `PREEMPTED` state in `sacct`.

`sacct -X` reads the per-job records straight from `slurmdbd`, so finished
jobs (and their final state — `COMPLETED`, `CANCELLED`, `PREEMPTED`) show up
the moment they end. The `State` and `Elapsed` columns are where you watch
the preemption story play out; `CPUTimeRAW` (CPU-seconds = `AllocCPUS` ×
`Elapsed`) is the raw consumption the `UsageFactor=0.5` then bills at half
rate against `GrpTRESMins`. We use `sacct` rather than
`sreport AccountUtilizationByUser` here because `sreport` reads only the
**rolled-up** usage tables that `slurmdbd` aggregates hourly — so right after
a short demo it's usually empty, while `sacct` has the data immediately.

---

## 11. Tear down and re-run

```bash
./uninstall_all.sh           # full cleanup (head + compute, both modes)
./install_all.sh XX          # or: ./install_all.sh --configless XX
```

`uninstall_all.sh` runs the destroy plays for both `~/slurm` and
`~/head_node`, sweeps any configless conf-cache on compute, and removes the
working copies from `$HOME` so the next install starts clean. Safe to run
more than once — it skips whatever's already gone. See `INSTALL.md` section
8 for details.

---

## Where to look for more

- `commands` — the runnable source of truth for every step above (what to type).
- `Storage-options.md` — where to run your jobs from on each shared filesystem
  (Ceph, BeeGFS, Lustre, Storage Scale), with the one-time work-dir setup.
- `INSTALL.md` — what `install_all.sh` does to your cluster, step by step.
- `README.md` — quick orientation and the `install_all.sh` reference.
