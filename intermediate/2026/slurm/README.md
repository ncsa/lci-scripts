# slurm - one-command Slurm cluster install (storage built separately)

Self-contained bundle that installs a working Slurm cluster in one command: head node
configuration, then Slurm `25.11.6` built from source and deployed to the compute
nodes. Use this when the focus is configuring and *using* the scheduler, not installing
it.

This variant does **not** set up shared storage — the Chosen Storage Solution is built
in a previous lab, so the head-node playbook here skips the shared-storage server and
compute-node autofs mounts. See `Storage-options.md` for how to run the lab from
whichever filesystem that lab left mounted.

Everything `install_all.sh` needs is included here:

```
slurm/                          (this bundle)
├── install_all.sh              one-command installer
├── uninstall_all.sh            full teardown (classic + configless)
├── commands                    source of truth: every command, brief notes
├── INSTALL.md                  detailed: what install_all.sh actually does
├── HANDSONLAB.md               detailed: every lab section in `commands` (the "why")
├── README.md                   this file (quick start)
├── head_node/                  head-node playbook: CRB, timesync, packages
└── slurm/                      scheduler playbook: Slurm from source + deploy
```

### Which document do you want?

- **In a hurry, just want to run something** → `commands` (top to bottom).
- **Want to understand the install** → `INSTALL.md`.
- **Working through the lab exercises** → `HANDSONLAB.md` alongside `commands`.
- **Already lost** → start here, then `commands`.

## Usage

Run as **root on your head node** (`lci-head-XX-1`):

```bash
sudo -i
git clone https://github.com/ncsa/lci-scripts.git ~/lci-scripts   # skip if already cloned
cd ~/lci-scripts/intermediate/2026/slurm
./install_all.sh 07               # use YOUR cluster number; prompts if omitted
./install_all.sh --configless 07  # configless variant (see below)
```

The cluster number is the only required input. The script:

1. Copies the `head_node/` playbook to `~/head_node`, sets your cluster number in
   `hosts.ini`, installs `ansible-core` on the head + compute nodes
   (`installansible.sh`), and runs the head-node playbook.
2. Copies the `slurm/` playbook to `~/slurm`, sets your cluster number in `hosts.ini`
   and `group_vars/cluster_params.yml`, and runs it — builds Slurm from source on the
   head node, deploys to the compute nodes, and starts `slurmctld`/`slurmdbd` (head)
   and `slurmd` (compute).

The script works on copies in your home directory, so this bundle is left unchanged.

## Configless mode (`--configless`)

Slurm 20.02+ supports a "configless" deployment where compute nodes do **not**
keep a local copy of `slurm.conf`; instead, `slurmd` is launched with
`--conf-server <controller>` and fetches the config from `slurmctld` at startup.
This bundle is already wired for it on the controller side — `slurm.conf`
contains `SlurmctldParameters=enable_configless`, and the compute `slurmd.service`
unit calls `slurmd --systemd --conf-server $SLURMCTLD_HOST`.

The flag controls one thing: whether the playbook **also** writes
`/etc/slurm/slurm.conf` on the compute nodes.

- Without `--configless` (default): the playbook writes `/etc/slurm/slurm.conf`
  on each compute node. `slurmd --conf-server` still fetches the controller's
  copy at startup, so the local file is effectively shadowed but visible to
  students — good for "this is the config the node is running" inspection
  during the lab.
- With `--configless`: the compute-side `slurm.conf` write is skipped entirely.
  `/etc/slurm/slurm.conf` will not exist on compute nodes; `scontrol show
  config` on the compute node shows the controller's version. Edits to the
  head node's `slurm.conf` followed by `scontrol reconfigure` propagate
  automatically (no scp/rsync to compute needed).

Verify the configless install:

```bash
ssh lci-compute-07-1 ls -l /etc/slurm/slurm.conf   # No such file or directory
ssh lci-compute-07-1 scontrol show config | head   # shows controller config
```

## A "FAILED!...ignoring" message during install is expected

Partway through the Slurm play you will see something like:

```
fatal: [lci-head-XX-1]: FAILED! => {... "cmd": "mysql -e \"SELECT 1 FROM mysql.user
WHERE user='slurm' AND host='localhost';\" ... | grep -q 1", "rc": 1 ...}
...ignoring
```

This is **normal** — it is a *check*, not an error. The task asks "does the `slurm`
MariaDB user already exist?" On a fresh install it does not, so `grep` finds nothing
and returns a non-zero code. The task is marked `ignore_errors`, so Ansible prints
`...ignoring` and continues; the very next task uses that result to create the `slurm`
database and user. (On a re-run where the user already exists, the check passes
silently and the create step is skipped.) Let the install continue.

## Verify

```bash
sinfo                      # both compute nodes should show 'idle'
systemctl status slurmctld slurmdbd
ssh lci-compute-07-1 systemctl status slurmd
```

## Tear down and re-run

```bash
cd ~/slurm     && ansible-playbook -i hosts.ini destroy.yml
cd ~/head_node && ansible-playbook destroy.yml
~/lci-scripts/intermediate/2026/slurm/install_all.sh 07
```

## Requirements

- Rocky Linux 9.7 on head and compute nodes.
- Head node hostname set correctly and host-based SSH to the compute nodes working.

## After install — the lab

`commands` holds the sequence of commands the course actually focuses on. Work
through it on the head node after the install finishes:

1. Verify the install (services, `sinfo`).
2. ClusterShell setup and compute hostname fixes.
3. Group and user creation propagated across nodes.
4. Central rsyslog logging.
5. Running jobs with `srun` / `sbatch` and inspecting with `squeue` / `sacct`.
6. **Exercise 1** — Enabling fairshare.
7. **Exercise 2** — Hierarchical fairshare (groups *and* users).
8. **Exercise 3** — Priority issues (reservations + a high-priority partition).
9. **Exercise 4** — Limiting groups with accounting (`GrpTRESMins`, billing weights).
10. **Exercise 5** — Preemption for a low-priority QOS.

Replace `XX` with your cluster number throughout `commands`.

For the **why** behind each step — what `slurm.conf` knobs you're flipping, what to
watch for in `sshare` / `sprio` / `squeue` output, why the hostname-fix one-liner is
shaped the way it is, etc. — see `HANDSONLAB.md`. `commands` is the source of truth for
*what to run*; `HANDSONLAB.md` is the source of truth for *why*.
