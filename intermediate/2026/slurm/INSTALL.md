# INSTALL.md — what `install_all.sh` actually does

This document explains what gets installed on your cluster when you run
`install_all.sh`, in the order it happens. It is written for the LCI
*Intermediate Schedulers* lab — the goal of the lab is to **configure
and use** Slurm, so `install_all.sh` exists to get you to a working
cluster quickly, without making the install itself the lesson.

If you just want to run it, see `README.md`. This file is for when you
want to understand or troubleshoot it.

---

## 1. Pre-flight: what `install_all.sh` itself does

`install_all.sh` is a bash wrapper around two Ansible playbooks. Before
it touches anything it:

1. **Checks it's running as root.** Both playbooks `become: yes`
   locally (for the head node) and over SSH (for compute nodes), so
   the wrapper requires `EUID=0`. Use `sudo -i` first.
2. **Parses flags.** Currently only `--configless` (see section 6),
   plus `-h`/`--help`. The cluster number is positional.
3. **Resolves the cluster number** (`01`–`40`). Either passed as
   the first non-flag argument or prompted. The script zero-pads
   single digits (`7` → `07`) and validates the format. The number
   is used to build host names: `lci-head-NN-1` and
   `lci-compute-NN-{1,2}`.
4. **Copies the playbooks to `$HOME`.** It does not run the source
   tree in place. `head_node/` is copied to `~/head_node` and
   `slurm/` is copied to `~/slurm`. This lets the script substitute
   the cluster number into `hosts.ini` and `cluster_params.yml`
   without modifying the version-controlled bundle, and means a
   re-run starts from a clean working copy (`rm -rf` on each
   destination first).
5. **Patches the cluster number.** `sed` replaces the literal
   `-XX-` in `hosts.ini` with `-NN-`, and rewrites the
   `cluster_number:` line in `slurm/group_vars/cluster_params.yml`
   to the chosen value. Everything else in the playbooks derives
   from this one number via Jinja2.

After that, two playbooks run in sequence.

---

## 2. Step 1/2 — `head_node` playbook (`~/head_node/playbook.yml`)

This playbook does the OS-level prep on the head node and the two
compute nodes. It does **not** install Slurm.

Before the playbook runs, `bash installansible.sh` makes sure
`ansible-core` is present on the head and compute nodes (the head
needs it to run the play; compute nodes don't actually need it for
this lab, but the helper script is shared with other labs).

Three roles run on the head node, then two of them re-run on
`all_nodes`:

### `crb` — enable the CodeReady Builder / PowerTools repo

Many of the Slurm build dependencies (e.g. `hdf5-devel`, `lua-devel`,
`munge-devel`, `libjwt-devel`) live in the CRB repo on RHEL-family 9.
On Rocky 9 this repo is shipped but disabled by default. The role
runs `dnf config-manager --set-enabled crb` so the dependency installs
in the Slurm role can find their packages. Runs on head + compute
because compute nodes also pull runtime deps from CRB.

### `timesync` — chrony / clock sync

Slurm and MUNGE are both time-sensitive: MUNGE credentials carry a
timestamp and will be rejected if the receiving node is more than a
few minutes off, and Slurm itself relies on consistent clocks for
job timing and scheduling. The role installs and enables `chronyd`
on every node so they stay in sync from the start.

### `head-node_pkg_inst` / `compute-node_pkg_inst`

Installs the baseline packages the lab assumes: editor, networking
tools, `epel-release`, `python3`, `rsync`, etc. The head-node
variant pulls a slightly larger set (build tools needed in step 2
arrive in the Slurm role itself, so this is just OS baseline).

### Verifying step 1 manually

```bash
ssh lci-head-NN-1 'dnf repolist enabled | grep -i crb'
ssh lci-compute-NN-1 'timedatectl status | head'
```

The head playbook also has a `destroy.yml` companion that removes
the packages and disables CRB — that's what `uninstall_all.sh`
calls in its second phase.

---

## 3. Step 2/2 — `slurm` playbook (`~/slurm/playbook.yml`)

This is the substantive part. It builds Slurm from source on the
head node and deploys it to the compute nodes. The build target is
pinned in `group_vars/cluster_params.yml`:

```yaml
slurm_vers:   '25.11.6'
pmix_release: '4.2.8'
```

`destroy.yml` is the inverse of this play (used by `uninstall_all.sh`).

### Head-node play (`hosts: head`, `connection: local`)

The play does **not** SSH back to itself — it runs as a local play
*on* the head node. Sequence:

1. **Install build deps.** `dnf` installs the full Slurm build
   chain: `munge-devel`, `hdf5-devel`, `pmix-devel`, `ucx-devel`,
   `lua-devel`, `libjwt-devel`, `libbpf-devel`, `json-c-devel`,
   `http-parser-devel`, `gcc`/`gcc-c++`, etc.
2. **Create the `slurm` user/group with UID/GID 600.** Pinned so
   compute nodes match head (the `slurm` user must have the same
   UID/GID across the cluster for shared spool dirs, accounting
   files, etc).
3. **Create the directory layout.**
   - `/opt/slurm`             (install prefix, owner `slurm:rocky` 0750)
   - `/etc/slurm`             (config)
   - `/var/log/slurm`         (logs, pre-touched: `slurmctld.log`,
                              `slurmdbd.log`, `slurmd.log` so daemons
                              don't bail on missing files at first start)
   - `/var/run/slurm`         (pid files)
   - `/var/spool/slurmd.spool` (`SlurmdSpoolDir`)
   - `/var/spool/slurm.state`  (`StateSaveLocation`)
4. **Initialize MUNGE.** Sets permissions on `/etc/munge`,
   `/var/lib/munge`, `/var/log/munge`. Generates `/etc/munge/munge.key`
   with `dd if=/dev/urandom bs=1 count=1024`, owned `munge:munge`
   mode `0400`. Enables and starts `munged`. This same key is rsynced
   to compute nodes later — MUNGE auth requires identical keys
   cluster-wide.
5. **Install and start MariaDB.** This is the backing store for
   `slurmdbd`. The block handles a subtle Rocky 9 case: if
   `mysql_secure_installation` was ever run, MariaDB root login
   fails (the password got set), so the play tests `mysql -e "SELECT 1"`,
   and on failure restarts MariaDB with `--skip-grant-tables`,
   resets root back to `unix_socket` auth, restarts, and verifies.
   Then it creates the `slurm` DB user and `slurm_acct_db` database.
   On first install you will see a `FAILED!...ignoring` line during the
   "does the slurm user already exist?" check — **this is normal**
   (see README).
6. **Download and build Slurm.** Skipped if a previous build exists
   under `/opt/slurm/{{ slurm_vers }}-built/sbin/slurmctld`.
   - Tarball from `download.schedmd.com/slurm/slurm-{{ slurm_vers }}.tar.bz2`
     into `/tmp`.
   - Configure flags:
     `--without-shared-libslurm --with-munge --with-hwloc --with-pmix
     --with-jwt --with-json --enable-slurmrestd --with-ucx --with-lua
     --enable-pam --sysconfdir=/etc/slurm
     --prefix=/opt/slurm/{{ slurm_vers }}-built`.
   - `make -j 2 && make install && make install-contrib`.
   - Symlink `/opt/slurm/current` → `/opt/slurm/25.11.6-built`.
   - `ldconfig` registers `/opt/slurm/current/lib64` (writes
     `/etc/ld.so.conf.d/slurm.conf`).
   - Adds `/opt/slurm/current/bin` to `PATH` via `/etc/profile.d/slurm.sh`.
     **Note:** `/etc/profile.d/` is sourced only by *login* shells, so the
     root shell that ran `install_all.sh` won't have Slurm on `PATH` until
     you `source /etc/profile.d/slurm.sh` (or log out and `sudo -i` again).
     See troubleshooting, section 9.
7. **Deploy config templates.**
   - `slurm.conf`     ← `roles/slurm-source/templates/slurm.conf.j2`
   - `slurmdbd.conf`  ← `roles/slurm-source/templates/slurmdbd.conf.j2`
   - `job_container.conf` (empty, touched)
   All driven by `cluster_params.yml` — see section 4.
8. **Deploy systemd units.**
   - `slurmctld.service`, `slurmdbd.service`, `slurmrestd.service`
     (static copies from `roles/slurm-source/files/`).
9. **Start services on the head node only.**
   - `slurmdbd` first (port `6819`), wait for it.
   - Then `slurmctld` (port `6817`), wait for it.
   - **No `slurmd` on the head node** — head node is controller only.

### Compute-node play (`hosts: all_nodes`)

Runs against `lci-compute-NN-{1,2}` over SSH. The head node has
already built Slurm; compute nodes don't rebuild — they pull the
installed tree.

1. **Create `slurm` user/group (UID/GID 600).** Same numbers as the
   head.
2. **Install runtime deps.** `munge`, `hwloc`, `pmix`, `json-c`,
   `libjwt`, `ucx`, `lua`, `http-parser`, `lz4`, `numactl`, `dbus`.
3. **Rsync `/opt/slurm` from the head node.** Uses
   `ansible.posix.synchronize` with `delegate_to: groups['head'][0]`,
   so the rsync runs *from* the head *to* the compute node. Recreates
   the `/opt/slurm/current` symlink and re-runs `ldconfig`.
4. **Copy the MUNGE key from the head.** Same `synchronize` pattern.
   Sets owner `munge:munge` mode `0400` and starts `munged`.
5. **Deploy `slurm.conf` (classic mode only).** Same template as the
   head, written to `/etc/slurm/slurm.conf`. **In configless mode
   this step is skipped** — see section 6.
6. **Write `/etc/default/slurmd`.** Templates a single variable:
   `SLURMCTLD_HOST=lci-head-NN-1`. The systemd unit reads this via
   `EnvironmentFile=-/etc/default/slurmd`.
7. **Install `slurmd.service`** and reload systemd.
   The shipped unit's `ExecStart` is:
   ```
   /opt/slurm/current/sbin/slurmd --systemd --conf-server $SLURMCTLD_HOST $SLURMD_OPTIONS
   ```
   That `--conf-server` flag is what makes configless work; in
   classic mode it's harmless because `slurmd` prefers a local
   `slurm.conf` if one is present (see section 6 for the actual
   precedence).
8. **Wait for `slurmctld` on port 6817**, then start and enable
   `slurmd`.

### Verifying step 2 manually

```bash
# On the head node:
systemctl status slurmctld slurmdbd
sinfo                          # both compute nodes should show 'idle'

# Then jump to a compute node:
ssh lci-compute-NN-1 systemctl status slurmd
```

---

## 4. The config templates

The two important templates live under
`slurm/roles/slurm-source/templates/`:

| Template            | Lives at on host    | Driven by                          |
|---------------------|---------------------|------------------------------------|
| `slurm.conf.j2`     | `/etc/slurm/slurm.conf` | `cluster_params.yml` + inventory `groups['head'][0]` |
| `slurmdbd.conf.j2`  | `/etc/slurm/slurmdbd.conf` | `db_pwd` from `cluster_params.yml` |
| `slurmd_defaults.j2`| `/etc/default/slurmd`     | `groups['head'][0]`                  |

Variables that flow through `cluster_params.yml`:

```yaml
cluster_number:   '01'                              # set by install_all.sh
slurm_vers:       '25.11.6'                         # build target
pmix_release:     '4.2.8'
slurm_controller: 'lci-head-{{ cluster_number }}-1' # used in slurm.conf
cluster_name:     'cluster'                         # ClusterName=
db_pwd:           'lcilab2026'                      # slurmdbd StoragePass
slurm_nodes:      "lci-compute-{{ cluster_number }}-[1-2]"
CPU_num:          '2'                               # node CPUs
Sockets:          '2'
Cores:            '1'
mem:              '7500'                            # MB per node
partition_name:   'lcilab'
```

If you want a change to *persist across reinstalls*, edit the
`.j2` template (and/or `cluster_params.yml`), not the deployed
`/etc/slurm/*.conf`. The "live edit, then `scontrol reconfigure`"
workflow used in the exercises only changes the running config —
re-running the playbook re-renders the template and overwrites
the live file.

Key things `slurm.conf.j2` already sets that the exercises rely on:

- `SlurmctldParameters=enable_configless`
- `PriorityType=priority/multifactor` and `PriorityWeight*` values
- `PreemptType=preempt/qos`, `PreemptMode=CANCEL`
- `AccountingStorageEnforce=limits,qos`
- `ProctrackType=proctrack/cgroup`, `TaskPlugin=task/cgroup,task/affinity`
- `JobContainerType=job_container/tmpfs`
- `SchedulerType=sched/backfill` with the standard backfill tuning

---

## 5. Cluster anatomy after a successful install

```
                   +----------------------------+
                   |   lci-head-NN-1   (head)   |
                   |                            |
                   |   chronyd                  |
                   |   munged                   |
                   |   mariadb       :3306      |
                   |   slurmdbd      :6819      |
                   |   slurmctld     :6817      |
                   |                            |
                   |   /opt/slurm/current ----+ |
                   |   /etc/slurm/*.conf       \|
                   +-----------+----------------+
                               |   rsync /opt/slurm + munge.key
                               |   (controller pushes to compute)
                               |
              +----------------+----------------+
              |                                 |
   +----------v-----------+         +-----------v----------+
   | lci-compute-NN-1     |         | lci-compute-NN-2     |
   |   chronyd            |         |   chronyd            |
   |   munged             |         |   munged             |
   |   slurmd      :6818  |         |   slurmd      :6818  |
   |   /opt/slurm/current |         |   /opt/slurm/current |
   |                      |         |                      |
   |   classic:           |         |   classic:           |
   |     /etc/slurm/      |         |     /etc/slurm/      |
   |       slurm.conf     |         |       slurm.conf     |
   |   configless:        |         |   configless:        |
   |     no slurm.conf;   |         |     no slurm.conf;   |
   |     cached under     |         |     cached under     |
   |     SlurmdSpoolDir   |         |     SlurmdSpoolDir   |
   +----------------------+         +----------------------+
```

Ports actually in use (no firewall is configured by the playbook,
this is a lab):

| Port  | Daemon        | Where           |
|-------|---------------|-----------------|
| 6817  | `slurmctld`   | head only       |
| 6818  | `slurmd`      | compute only    |
| 6819  | `slurmdbd`    | head only       |
| 3306  | `mariadb`     | head, localhost |

Auth: every Slurm RPC and `srun` interaction between daemons and
clients is authenticated by MUNGE, which requires
`/etc/munge/munge.key` to be the **same file** on every node.

---

## 6. Classic vs. configless (`--configless`)

`install_all.sh --configless NN` flips one decision: whether the
playbook writes `/etc/slurm/slurm.conf` on the compute nodes.

The controller side is identical in both modes:

- `slurm.conf` on the head has `SlurmctldParameters=enable_configless`.
- The compute `slurmd.service` calls
  `slurmd --systemd --conf-server $SLURMCTLD_HOST`.

Effect on compute nodes:

| Mode        | `/etc/slurm/slurm.conf` on compute | How slurmd gets its config             |
|-------------|------------------------------------|-----------------------------------------|
| classic     | written by playbook                | local file (slurmd uses the local copy) |
| configless  | not written                        | fetched from slurmctld at slurmd start, cached under SlurmdSpoolDir |

Why bother with configless: with it on, you can edit
`/etc/slurm/slurm.conf` **only on the head node**, run
`scontrol reconfigure`, and the compute nodes pick up the new
config automatically. No scp/rsync to compute. This is the model
real-world clusters use to scale past a handful of nodes.

What the flag actually changes in the playbook (`slurm/playbook.yml`):

```yaml
- name: Deploy slurm.conf from template
  ansible.builtin.template:
    src: roles/slurm-source/templates/slurm.conf.j2
    dest: /etc/slurm/slurm.conf
    ...
  when: not (configless | default(false) | bool)   # <-- gate
```

That `when:` is the entire difference. The script passes
`-e configless=true|false` to `ansible-playbook` based on the flag.

Verify a configless install:

```bash
ssh lci-compute-NN-1 ls -l /etc/slurm/slurm.conf   # No such file or directory
ssh lci-compute-NN-1 scontrol show config | head   # shows controller's config
```

To switch a running classic install to configless (no reinstall
required):

```bash
ssh lci-compute-NN-1 'rm /etc/slurm/slurm.conf && systemctl restart slurmd'
```

To go the other way, re-run the playbook *without* `--configless`
(or `ansible-playbook -i hosts.ini -e configless=false playbook.yml`
in `~/slurm`).

---

## 7. What's installed where (cheat sheet)

| Path                                  | Owner         | Notes                          |
|---------------------------------------|---------------|--------------------------------|
| `/opt/slurm/25.11.6-built/`           | slurm:slurm   | install prefix                 |
| `/opt/slurm/current`                  | symlink       | → `25.11.6-built`              |
| `/opt/slurm/current/bin`              |               | added to `PATH` via `/etc/profile.d/slurm.sh` |
| `/opt/slurm/current/lib64`            |               | added to `ldconfig` via `/etc/ld.so.conf.d/slurm.conf` |
| `/etc/slurm/slurm.conf`               | slurm:slurm   | head always; compute in classic only |
| `/etc/slurm/slurmdbd.conf`            | slurm:slurm   | head only, 0600                |
| `/etc/slurm/job_container.conf`       | slurm:slurm   | head only, empty               |
| `/etc/munge/munge.key`                | munge:munge   | 0400, identical on all nodes   |
| `/etc/default/slurmd`                 | root:root     | compute only                   |
| `/etc/systemd/system/slurmctld.service` | root:root   | head only                      |
| `/etc/systemd/system/slurmdbd.service`  | root:root   | head only                      |
| `/etc/systemd/system/slurmrestd.service`| root:root   | head only                      |
| `/etc/systemd/system/slurmd.service`    | root:root   | compute only                   |
| `/var/log/slurm/*.log`                | slurm:slurm   |                                |
| `/var/run/slurm/*.pid`                | slurm:slurm   |                                |
| `/var/spool/slurmd.spool`             | slurm:slurm   | `SlurmdSpoolDir`               |
| `/var/spool/slurm.state`              | slurm:slurm   | `StateSaveLocation` (head)     |
| `/var/lib/mysql/`                     | mysql:mysql   | head only (MariaDB data)       |
| `~/slurm`, `~/head_node`              | root          | working copies; removed by `uninstall_all.sh` |

The version-controlled bundle (the directory you're reading
right now) is **never modified** by `install_all.sh`. Everything
the script does happens to the working copies in `$HOME`.

---

## 8. Uninstall (`uninstall_all.sh`)

`uninstall_all.sh` reverses the install. It calls:

1. `~/slurm/destroy.yml` — stops `slurmctld`/`slurmdbd`/`slurmd`/`munged`
   on head and compute, removes systemd units, deletes `/opt/slurm`,
   `/etc/slurm`, `/etc/munge`, all the `/var/log/slurm`, `/var/spool/slurm*`,
   and `/var/run/slurm` paths, removes the `slurm` user/group on
   every node, drops the `slurm_acct_db` database and the `slurm`
   DB user, and runs `ldconfig`.
2. An extra sweep that explicitly removes any cached configless
   config under `/var/spool/slurmd*/conf-cache/` and any stray
   `/etc/slurm/slurm.conf` on compute (belt-and-suspenders for
   the configless case, harmless in classic mode).
3. `~/head_node/destroy.yml` — stops MariaDB, uninstalls
   `mariadb-server`/`munge*`/build-deps, removes `/var/lib/mysql`,
   disables the `powertools` repo.
4. `rm -rf ~/slurm ~/head_node` so the next install starts clean.

Works whether the original install was classic or configless. It
auto-detects the mode (by checking the compute node for a local
`slurm.conf`) and prints which one it found, but the cleanup steps
are the same set in both cases.

If one of the two working dirs is missing (interrupted install,
partial cleanup), `uninstall_all.sh` will run whatever it can and
skip the missing piece with a message instead of bailing out.

---

## 9. Troubleshooting

**`sinfo`/`sacctmgr`: "command not found" right after the install
(or `scripts/create_users_groups.sh` aborts with "sacctmgr not
found").** The install wrote `/etc/profile.d/slurm.sh` (which prepends
`/opt/slurm/current/bin` to `PATH`), but `/etc/profile.d/` is sourced
only by *login* shells. The root shell that ran `install_all.sh` was
started before the install existed, so it never picked it up. Fix it in
the current shell, or get a fresh login shell:
```bash
source /etc/profile.d/slurm.sh   # this shell, now
# or
exit; sudo -i                    # fresh login shell
```
Sourcing `~/.bashrc` does **not** help — `.bashrc` doesn't read
`/etc/profile.d/`.

**`AccountingStorageUser=slurm` defunct error.** Removed in Slurm
23.11, fatal in 25.x. The shipped `slurm.conf.j2` has this line
commented out. If you see it, you're running an older copy of the
template; pull a fresh copy and re-run the playbook.

**`slurmd` won't start, "no slurm.conf" in logs.** Either configless
is on but `slurmctld` is unreachable on port 6817, or you're in
classic mode and `/etc/slurm/slurm.conf` is missing. Check:
```bash
ss -lntp | grep 6817        # on head
ssh lci-compute-NN-1 'ls /etc/slurm/ ; systemctl status slurmd -l'
```

**MUNGE "Invalid credential" / "expired credential".** Clocks
out of sync, or the key on this node doesn't match the head.
Check `timedatectl status` and compare `md5sum /etc/munge/munge.key`
across nodes.

**`sinfo` shows nodes as `down*` or `drain`.** `slurmctld` can't
reach `slurmd`. Confirm `slurmd` is running on the compute node,
that you can reach port 6818 from the head, and that the
hostname `slurmctld` is trying to use (the `NodeName` in
`slurm.conf`) actually resolves and matches what `hostname` says
on the compute side (a `.novalocal` suffix is a common gotcha;
see the `commands` file).

**`mysql -e "SELECT 1 FROM mysql.user..."` task FAILED, then
"...ignoring".** Normal on a fresh install. The next task uses
that result to create the slurm DB user. See README.

**Build deps missing (`hdf5-devel`, `libjwt-devel`, ...).** CRB
is not enabled. The `crb` role should have done this in step 1;
re-run `~/head_node/playbook.yml` or just
`dnf config-manager --set-enabled crb`.

---

## 10. Re-running the install

`install_all.sh` is idempotent against the working copies — the
first thing each phase does is `rm -rf ~/head_node` (or
`~/slurm`) and start over from the bundle. That means **any
hand-edits you made to `~/slurm/...` are lost** the next time
you run it. If you want changes to survive a re-run, put them in
the bundle (the version-controlled directory under
`intermediate/2026/slurm/`).

To reset between runs:

```bash
./uninstall_all.sh
./install_all.sh NN              # or --configless NN
```

`uninstall_all.sh` is safe to run more than once; it skips
whatever's already gone.
