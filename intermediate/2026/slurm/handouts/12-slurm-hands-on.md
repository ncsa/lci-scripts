# Module 12 — Slurm Hands-On

> Lab handout for the LCI Intermediate 2026 *Schedulers* track.
> Source of the slide deck at `slides/Current/12-slurm-hands-on/deck.py`.
> The commands you actually run live in `intermediate/2026/slurm/commands`;
> the *why* behind them is in `INSTALL.md` (install) and `LAB.md` (lab).

## How this lab works

Stand up a working Slurm cluster first, then bend it to five real complaints:
**setup · fairshare · priority · limits · preemption**.

One setup task (install + verify + ClusterShell + users), then five exercises.
Each exercise is framed as a complaint you'd actually get from a user or PI.
The point isn't to memorize commands — it's to feel how fairshare, priority,
and accounting limits interact on a live system.

---

## Setup — install Slurm with `install_all.sh`

You have 1 head node and 2 compute nodes. The head node runs `slurmctld` and
`slurmdbd`; the compute nodes run `slurmd`. Clone the bundle on the head
node and run the installer as root:

```bash
git clone https://github.com/ncsa/lci-scripts.git ~/lci-scripts
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
`mysql -e "SELECT 1 FROM mysql.user ..."` task. **This is normal** — it
is the "does the slurm DB user exist?" check. On a fresh install it
doesn't, so the playbook ignores the failure and creates it in the next
task.

### Verify before configuring

Three classes of problem show up here and all of them snowball if you push
past:

```bash
systemctl status slurmctld slurmdbd mariadb     # all should be active (running)
timedatectl status                              # MUNGE will fail later if clocks drift
sinfo                                           # both compute nodes 'idle'
ssh lci-compute-XX-1 systemctl status slurmd
```

If you used `--configless`, the local `slurm.conf` is intentionally absent
on compute — `slurmd` fetched the config from `slurmctld` at startup:

```bash
ssh lci-compute-XX-1 ls /etc/slurm/slurm.conf       # No such file
ssh lci-compute-XX-1 scontrol show config | head    # served by controller
```

If a compute node shows `down*`: almost always MUNGE key mismatch, a
`.novalocal` hostname suffix (fixed below), or `slurmd` never started.

### ClusterShell + four departments, eight users

ClusterShell's `clush` fans one command out to a host group — every later
step uses it. (This deck replaces the older `pdsh` instructions.)

```bash
dnf install -y clustershell
# Edit /etc/clustershell/groups.d/local.cfg, add:
#   head: lci-head-XX-1
#   compute: lci-compute-XX-[1-2]
clush -g compute uptime              # sanity check
```

Cloud-init often leaves a `.novalocal` suffix on the compute hostname —
fix it before configuring Slurm. The exact `clush` one-liner is in
`commands` section 2 (and explained in `LAB.md`).

Then create 4 departments × 2 users + the matching Slurm accounts. The
exercises name specific users:

| Department  | Slurm account | Users                |
|-------------|---------------|----------------------|
| biology     | biology       | bob, alice           |
| engineering | engineering   | justin, katie        |
| chemistry   | chemistry     | carol, dave          |
| physics     | physics       | erin, frank          |

Shortcut — runs the whole section idempotently:

```bash
./scripts/create_users_groups.sh
```

`slurm.conf` ships with `AccountingStorageEnforce=limits,qos`, so jobs
must run under a valid Slurm account; the script sets `DefaultAccount=`
per user so `sbatch` doesn't need `--account=` every time.

### What `install_all.sh` already wired up

The shipped `slurm.conf` template already has the machinery the exercises
need — you only edit per-exercise tuning, not these:

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

**Live edits vs. persistent changes.** Editing `/etc/slurm/slurm.conf` and
running `scontrol reconfigure` applies a change immediately — but the
next time you run `install_all.sh` it re-renders that file from the
template and your change is gone. To make a change permanent, put it in:

```
intermediate/2026/slurm/slurm/roles/slurm-source/templates/slurm.conf.j2
```

---

## Exercise 1 — Enabling fairshare

**Complaint.** Professor Bob runs a few 4-core jobs a week; others flood
the queue with single-core jobs and bury him.

**Goal.** Every user gets an equal share; fairshare reacts inside the lab
session (default decay is ~week — useless for live demo).

Edit `/etc/slurm/slurm.conf` and add:

```
PriorityDecayHalfLife=00:10:00
PriorityCalcPeriod=00:01:00
FairShareDates=6
```

Keep `PriorityFlags=DEPTH_OBLIVIOUS` commented out so the depth-6 setting
matters. Apply live:

```bash
scontrol reconfigure
```

Equalize the four accounts:

```bash
sacctmgr -i modify account biology     set fairshare=1
sacctmgr -i modify account engineering set fairshare=1
sacctmgr -i modify account chemistry   set fairshare=1
sacctmgr -i modify account physics     set fairshare=1
```

Drive load from two users and watch priorities diverge. First, install
the reusable load generator (used in exercises 1, 2, and 5):

```bash
cp scripts/load.sh /root/load.sh && chmod +x /root/load.sh
# usage: /root/load.sh USER COUNT [PARTITION] [QOS]
```

Then:

```bash
/root/load.sh justin 15
/root/load.sh bob 3
sleep 60
sprio -l                                      # per-job fairshare component
sshare -a                                     # per-user effective usage/share
squeue -o "%.8i %.9P %.8u %.10Q %R"           # %Q = priority
```

Bob's three jobs should land with higher priority than Justin's fifteen
because Justin's lab-time usage is climbing fast.

---

## Exercise 2 — Fairshare for groups *and* users

**Setup.** All departments must share the cluster evenly, AND users must
share evenly *inside* their department. Hierarchical fairshare.

Equal shares at both levels (accounts are already 1 each from exercise 1):

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

Inspect the share tree:

```bash
sshare -l                                    # per-association Level FS
```

The teaching demo — the *katie* moment:

```bash
/root/load.sh justin 15       # engineering over-uses
sleep 60
sshare -a                     # katie's share drops too (same account)
sprio -l
```

Katie personally submitted nothing. Her share drops because her
account-mate Justin flooded the queue. That's the whole point of
hierarchical fairshare: the *account* has a budget that everyone in the
account shares, so the group polices itself.

---

## Exercise 3 — Issues with priority

**Complaint.** Bob is back — paper deadline, can't get high-priority
jobs through even with fairshare on.

### (a) Quick fix — a reservation

```bash
scontrol create reservation \
  ReservationName=bob_deadline \
  StartTime=now Duration=00:20:00 \
  Users=bob \
  Nodes=lci-compute-XX-1
scontrol show reservation
sudo -u bob sbatch --reservation=bob_deadline -p lcilab -n1 --wrap "sleep 300"
```

A reservation cuts the line for a named user during a specific window.
Surgical and temporary.

### (b) Permanent fix — a higher-priority partition

Add to `/etc/slurm/slurm.conf` (and the `.j2` template to persist):

```
PartitionName=high Nodes=lci-compute-XX-[1-2] Default=No \
  PriorityTier=100 QOS=normal AllowQOS=normal
```

```bash
scontrol reconfigure
sinfo -o "%.12P %.5a %.10l %.6D"     # confirm 'high' exists
sudo -u bob    sbatch -p high   -n1 --wrap "sleep 300"
sudo -u justin sbatch -p lcilab -n1 --wrap "sleep 300"
squeue -o "%.8i %.9P %.8u %.10Q %R"
```

**`PriorityTier` wins over any per-job priority.** A higher-tier
partition's pending jobs schedule before any lower-tier partition's
jobs, regardless of fairshare or per-job priority. Powerful and
easy to abuse — which is exactly what exercise 4 punishes.

---

## Exercise 4 — Limiting groups with accounting

**Setup.** IT sells resources to each department. Cap each at 20 CPU-hours
(= 1200 CPU-minutes), and make the `high` partition cost 2× normal.

`AccountingStorageEnforce=limits` is already on, so the cap kicks in
immediately:

```bash
sacctmgr -i modify account biology     set GrpTRESMins=cpu=1200
sacctmgr -i modify account engineering set GrpTRESMins=cpu=1200
sacctmgr -i modify account chemistry   set GrpTRESMins=cpu=1200
sacctmgr -i modify account physics     set GrpTRESMins=cpu=1200
sacctmgr show assoc format=Account,User,GrpTRESMins
```

`GrpTRESMins=cpu=1200` is the cumulative CPU-minute cap for the account.
It's a meter, not a rate limit — usage accumulates over time. When the
cap is hit, new jobs pend with `Reason=GrpTRESMins`.

Make `high` cost 2× via per-partition billing weights. Edit
`/etc/slurm/slurm.conf` and give `high` its own line (`lcilab` keeps the
default `CPU=1.0`):

```
PartitionName=high ... TRESBillingWeights="CPU=2.0,Mem=.25G,gres/gpu=3.0"
```

```bash
scontrol reconfigure
sudo -u carol sbatch -p lcilab -n2 --wrap "sleep 600"   # chemistry
sleep 60
sreport cluster AccountUtilizationByUser start=$(date +%Y-%m-%d) -t Minutes
squeue -o "%.8i %.9P %.8u %.8a %R"                      # %R = reason
```

A 60-minute one-CPU job bills 60 CPU-minutes on `lcilab` but 120 on `high`
— the natural disincentive against camping on the fast lane.

---

## Exercise 5 — Preemption for a low queue

**Setup.** Users want a low-priority queue that soaks up idle cycles,
yields to normal work, and bills at half cost. Cheap compute in
exchange for no guarantee — the "scavenger" or "spot" model.

`PreemptType=preempt/qos` and `PreemptMode=CANCEL` are already set.

```bash
sacctmgr -i add qos low \
  set Priority=0 \
  UsageFactor=0.5 \
  Preempt= \
  Flags=
sacctmgr -i modify qos normal set Preempt=low
```

- `Priority=0` → last in line for scheduling
- `UsageFactor=0.5` → bills at half rate against `GrpTRESMins`
- `Preempt=` (empty) → `low` does NOT preempt anything else
- `normal set Preempt=low` → `normal` preempts (cancels) `low` jobs

Allow the QOS on the partition (`AllowQOS` is mandatory — without it,
`sbatch -q low` returns "Invalid qos"). Edit `/etc/slurm/slurm.conf`:

```
PartitionName=lcilab ... QOS=normal AllowQOS=normal,low
```

```bash
scontrol reconfigure
sacctmgr show qos format=Name,Priority,UsageFactor,Preempt
```

Demo:

```bash
/root/load.sh justin 4              # fills 2 nodes × 2 CPUs (normal)
sudo -u bob sbatch -p lcilab -q low -n1 --wrap "sleep 600"
squeue -o "%.8i %.9P %.8u %.6q %.10Q %R"   # %q = QOS; low job pending
sreport cluster AccountUtilizationByUser start=$(date +%Y-%m-%d) -t Minutes
```

`CANCEL` is the simplest preemption mode for a demo. Production scavenger
queues usually use `REQUEUE` so the displaced job ends up back in the
queue instead of dying outright. `SUSPEND` and `GANG` are the other
options — discuss the trade-offs.

---

## Tear down and re-run

```bash
./uninstall_all.sh           # full cleanup, head + compute, classic + configless
./install_all.sh XX          # or: ./install_all.sh --configless XX
```

See `INSTALL.md` § 8 for what `uninstall_all.sh` actually does.

---

## Where to look for more

- `commands` — the runnable source of truth for every step above.
- `INSTALL.md` — what `install_all.sh` does to your cluster, step by step.
- `LAB.md` — long-form explanation of every lab section (the "why").
- `README.md` — quick orientation.
