# Module 12 — Slurm Hands-On Lab

> The detailed companion for the LCI Intermediate 2026 *Schedulers* track.
> Source of the slide deck at `slides/Current/12-slurm-hands-on/deck.py`.
>
> **`commands` is the source of truth for *what to run*; this file is the
> source of truth for *why*.** Run the commands on your head node
> (`lci-head-XX-1`, where `XX` is your cluster number) as root.
>
> For the install side of things — what `install_all.sh` actually does to
> the cluster, step by step — see `INSTALL.md`.

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
```

The `[1-2]` is `clush`'s native range syntax — it expands to
`lci-compute-XX-1,lci-compute-XX-2`. The `login:` group is the same host as
`head:`; it's there because some `clush` config recipes expect a login
group, and giving it the head's name is a no-op.

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
`lci-compute-XX-1`. Slurm's `NodeName` in `slurm.conf` is the bare form
(see `slurm.conf.j2`), and `slurmd` registers under `gethostname()` — so
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
   file ownership on any shared filesystem (NFS in other labs, or `/tmp`
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

Run this from your home directory (`cd ~`) as root:

```bash
cd ~
srun -p lcilab -N2 hostname
```

`-N2` means "give me 2 nodes." `srun` allocates them, runs `hostname` once
per node, prints the output, and exits. This is the cheapest way to confirm
jobs actually launch on the compute nodes.

**Why launch from `~`.** `srun` tries to start the remote task in the same
working directory you launched from. This lab has no shared filesystem
(NFS is a separate lab), so a path that exists only on the head node — e.g.
`~/lci-scripts/intermediate/2026/slurm` — makes `slurmd` on each compute
node print `error: couldn't chdir to '...': No such file or directory:
going to /tmp instead` and fall back to `/tmp`. It's a **warning, not a
failure** — `hostname` doesn't care what directory it runs in — but
launching from `~` (which root has on every node) keeps the output clean.

**Why `-p lcilab` is required.** The `lcilab` partition is defined
`Default=No` in `slurm.conf.j2`, so there is no *system default* partition.
Any job that omits `-p` — `srun -N2 hostname` on its own — fails with
`srun: error: Unable to allocate resources: No partition specified or
system default partition`. That's why every job command in this lab names
its partition explicitly. (If you'd rather make `lcilab` the default,
change `Default=No` to `Default=YES` in the template and re-run the
playbook — but the lab keeps it explicit on purpose.)

### `sbatch` — batch submission

A minimal job script `job.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=test
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --partition=lcilab
srun hostname
```

`#SBATCH` directives are equivalent to `sbatch` command-line flags. The
body uses `srun` instead of running commands directly so the work runs as a
Slurm step (which is what shows up in `sacct` later).

```bash
sbatch job.sh
```

Returns a job ID. The default stdout file is `slurm-<jobid>.out` in the
directory you submitted from.

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

**Live edits to `slurm.conf` are lost on the next playbook re-run.** The
playbook re-renders the file from its template. To make a change permanent,
put it in the template too:

```
intermediate/2026/slurm/slurm/roles/slurm-source/templates/slurm.conf.j2
```

The shipped `slurm.conf` template already has the machinery the exercises
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
cp scripts/load.sh /root/load.sh && chmod +x /root/load.sh
# usage: /root/load.sh USER COUNT [PARTITION] [QOS]
```

What's inside (7 lines):

```bash
#!/bin/bash
u=$1; n=$2; part=${3:-lcilab}; qos=${4:-normal}
for i in $(seq 1 "$n"); do
  sudo -u "$u" sbatch -p "$part" -q "$qos" -n1 \
    --wrap "sleep 600" -J "${u}-${i}" -o /dev/null
done
```

It submits N 10-minute `sleep` jobs as the named user, each requesting one
core. The 10-minute duration is long enough to see scheduling behavior; the
single-core size guarantees jobs are unit-allocatable so the queue actually
backs up.

Each user already has a `DefaultAccount` from section 3, so the script
doesn't need `--account=`. `-o /dev/null` discards the stdout files
(otherwise running 15 of these spams the cwd).

---

## 6. Exercise 1 — Enabling Fairshare

**Complaint.** Professor Bob runs a few 4-core jobs a week. Justin's lab
flat-out hammers the cluster with single-core jobs and crowds Bob out.

**Goal.** Give every user an equal *fairshare* slot at the queue and tune
the decay so the system reacts within minutes (the default ~week is useless
for a live demo).

### The three knobs you set in `slurm.conf`

```
PriorityDecayHalfLife=00:10:00
PriorityCalcPeriod=00:01:00
FairShareDates=6
```

- `PriorityDecayHalfLife=00:10:00` — past usage decays with a 10-min
  half-life. After 10 min, a unit of usage counts half; after 20 min, a
  quarter. The default is on the order of a week; we crank it down so the
  exercise gives feedback inside the lab session.
- `PriorityCalcPeriod=00:01:00` — recalculate every minute. Default is 5
  minutes. We tighten it so changes show up while you're watching `sprio`.
- `FairShareDates=6` — fairshare depth of 6 (root → account → user is 3;
  the depth lets the algorithm walk associations up to 6 levels deep). Keep
  `PriorityFlags=DEPTH_OBLIVIOUS` commented out — turning that on collapses
  the depth and changes the answer.

Apply live:

```bash
scontrol reconfigure
```

### Equal shares for all accounts

```bash
sacctmgr -i modify account biology     set fairshare=1
sacctmgr -i modify account engineering set fairshare=1
sacctmgr -i modify account chemistry   set fairshare=1
sacctmgr -i modify account physics     set fairshare=1
```

`fairshare=1` per account = each department's *share* of the cluster is
identical at the account level. Users inherit equal shares by default
underneath that, so individual users in different departments also get
equal weight.

### Verify

```bash
sshare -l                # per-association level FS and effective shares
sshare -a -l             # also include users; you can count the levels
scontrol show config | grep -i -E 'PriorityDecayHalfLife|PriorityCalcPeriod|FairShareDates|PriorityFlags'
```

`sshare` is the canonical fairshare inspection tool. `-l` switches to the
long view with "Level FS" — that's the per-level fairshare factor, the
number the priority calculation actually consumes.

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
(lab-time) usage is climbing fast while Bob's stays low. `sprio -l` shows
the fairshare *component* of each job's priority; `sshare -a` shows each
user's effective usage. `squeue` ordered by `%Q` (priority) makes the
result visible at a glance.

The exact numbers depend on how fast you ran the load — give it 60 seconds
and re-run `sprio -l` to see the values move.

---

## 7. Exercise 2 — Fairshare for Groups AND Users

**Setup.** Departments share the cluster evenly with each other, AND users
share evenly *inside* their department. This is hierarchical fairshare: the
algorithm applies shares at the account level AND the user level.

The account-level shares are already 1 each from exercise 1. Now make
user-level shares explicit:

```bash
sacctmgr -i modify account where account=biology,engineering,chemistry,physics set fairshare=1
sacctmgr -i modify user bob    set fairshare=1
sacctmgr -i modify user alice  set fairshare=1
sacctmgr -i modify user justin set fairshare=1
sacctmgr -i modify user katie  set fairshare=1
sacctmgr -i modify user carol  set fairshare=1
sacctmgr -i modify user dave   set fairshare=1
sacctmgr -i modify user erin   set fairshare=1
sacctmgr -i modify user frank  set fairshare=1
```

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

```bash
scontrol create reservation \
  ReservationName=bob_deadline \
  StartTime=now Duration=00:20:00 \
  Users=bob \
  Nodes=lci-compute-XX-1
scontrol show reservation
sudo -u bob sbatch --reservation=bob_deadline -p lcilab -n1 --wrap "sleep 300"
```

A reservation is a chunk of resources marked off for specific users during
a specific window. `Users=bob` means only Bob can submit into it.
`Nodes=lci-compute-XX-1` reserves the whole node. Bob has to ask for it
explicitly: `sbatch --reservation=bob_deadline ...`.

This is the cluster admin's "I owe you" — it cuts the line for a named user
without changing the scheduler's permanent policy. Surgical and temporary.

### (b) High-priority partition

Add to `/etc/slurm/slurm.conf` (and the `.j2` template to persist):

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
sudo -u bob    sbatch -p high   -n1 --wrap "sleep 300"
sudo -u justin sbatch -p lcilab -n1 --wrap "sleep 300"
squeue -o "%.8i %.9P %.8u %.10Q %R"
```

Bob's job (in `high`) should start before Justin's (in `lcilab`) even if
both are submitted in the opposite order — that's the tier doing its job.

---

## 9. Exercise 4 — Limiting Groups with Accounting

**Setup.** IT sells resources per department. Cap each department at 20
CPU-hours (= 1200 CPU-minutes), and make the `high` partition cost twice as
much as `lcilab`.

### CPU-time cap via `GrpTRESMins`

```bash
sacctmgr -i modify account biology     set GrpTRESMins=cpu=1200
sacctmgr -i modify account engineering set GrpTRESMins=cpu=1200
sacctmgr -i modify account chemistry   set GrpTRESMins=cpu=1200
sacctmgr -i modify account physics     set GrpTRESMins=cpu=1200
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
sudo -u carol sbatch -p lcilab -n2 --wrap "sleep 600"   # chemistry
sleep 60
sreport cluster AccountUtilizationByUser start=$(date +%Y-%m-%d) -t Minutes
squeue -o "%.8i %.9P %.8u %.8a %R"
```

`sreport AccountUtilizationByUser` is the canonical "who used what" report.
`-t Minutes` puts the answer in CPU-minutes, matching the cap units. The
`squeue` line at the end exposes the `Reason` column (`%R`) — that's where
you see `GrpTRESMins` once an account hits its cap.

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

```bash
sacctmgr -i add qos low \
  set Priority=0 \
  UsageFactor=0.5 \
  Preempt= \
  Flags=
```

- `Priority=0` — last in line for scheduling.
- `UsageFactor=0.5` — billed at half rate against `GrpTRESMins`. 10
  wall-minutes of one CPU bills as 5 CPU-minutes.
- `Preempt=` — empty: this QOS does NOT preempt anything else.
- `Flags=` — empty: no special handling beyond the above.

Then say which QOS preempts which:

```bash
sacctmgr -i modify qos normal set Preempt=low
```

`normal` preempts `low`. Because `slurm.conf` has `PreemptMode=CANCEL`,
"preempt" means "cancel the low job to free up the resources for a normal
job." `CANCEL` is the simplest preemption mode for a demo. Production
scavenger queues usually use `REQUEUE` so the displaced job ends up back in
the queue instead of dying outright; `SUSPEND` and `GANG` are the other
options — discuss the trade-offs.

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
sudo -u bob sbatch -p lcilab -q low -n1 --wrap "sleep 600"
squeue -o "%.8i %.9P %.8u %.6q %.10Q %R"   # %q = QOS; low job pending
sreport cluster AccountUtilizationByUser start=$(date +%Y-%m-%d) -t Minutes
```

The cluster has 2 nodes × 2 CPUs = 4 CPU slots. The 4 normal-QOS jobs from
Justin fill it. Bob's `-q low` job pends with `Reason=Resources`. Now
cancel one of Justin's jobs (or submit a new normal job and watch Bob's get
killed mid-flight) — the preemption side becomes visible in `sacct` as
state `PREEMPTED`.

The half-cost shows up in `sreport`: Bob's low-QOS time should be listed at
50% of wall.

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
- `INSTALL.md` — what `install_all.sh` does to your cluster, step by step.
- `README.md` — quick orientation and the `install_all.sh` reference.
