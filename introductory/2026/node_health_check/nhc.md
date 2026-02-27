# NHC Installation and Configuration Lab

## Part 1: Installation and Local Configuration

NHC is a lightweight, bash-based framework designed to be flexible and extensible.
The goal is to prevent jobs from running on unhealthy nodes by integrating
directly with your resource manager.

### 1. Compile and Install on a "Master" Node

Choose one node from your cluster to act as the source for your installation.

* **Download**: Obtain the latest release from the [official NHC GitHub](https://github.com/mej/nhc).

* **Compile**: Run the following commands to install NHC into standard system paths:

```bash
./configure --prefix=/usr --sysconfdir=/etc
make
sudo make install

```

* **Verify**: Ensure the default configuration file exists at `/etc/nhc/nhc.conf`.



### 2. Configure Slurm Integration (`/etc/sysconfig/nhc`)

Edit the sysconfig file on your master node to define how NHC interacts with
Slurm. This ensures that when a check fails, the node is automatically
drained with a clear reason.

```bash
# Set Resource Manager to Slurm
NHC_RM=slurm

# Set a safety timeout for checks (in seconds)
TIMEOUT=250

# Define the 'Offline' command to DRAIN nodes in Slurm
OFFLINE_NODE="scontrol update NodeName=$HOSTNAME State=DRAIN Reason='NHC: $NHC_CHECK_RETSTR'"

```

### 3. Define CPU-Only Health Checks (`/etc/nhc/nhc.conf`)

Populate your configuration file with checks relevant to your `s[0-300]` range.

```bash
### Global System Checks
# Verify root is writable and Slurm is running
* || check_fs_mount_rw /
* || check_ps_service -u root -S slurmd

### Targeted CPU Checks (Nodes s0-s300)
# Verify 2 physical CPUs and 64 cores
s[0-300] || check_hw_cpuinfo 2 64 64

# Verify baseline 128GB RAM
s[0-300] || check_hw_physmem 128GB 128GB 5%

# Target 'Fat' memory nodes specifically
s[250-260] || check_hw_physmem 2000GB 2000GB 5%

```

---

## Part 2: Cluster-Wide Deployment with ClusterShell

Once your master node is configured, use `clush` to push the installation to
your target nodes (e.g., `s[1-3]`).

### 1. Bundle the Installation

Create a tarball on your master node containing the binary and all relevant configurations.

```bash
sudo tar -czvf /tmp/nhc_bundle.tar.gz /usr/sbin/nhc /etc/nhc/ /etc/sysconfig/nhc

```

### 2. Distribute and Extract via `clush`

Use `clush` to copy the bundle to the `/tmp` directory of your target nodes and
extract it to the root filesystem.

```bash
# Copy the bundle to target nodes
clush -w s[1-3] --copy /tmp/nhc_bundle.tar.gz --dest /tmp/

# Extract the bundle (requires sudo)
clush -w s[1-3] "sudo tar -xzvf /tmp/nhc_bundle.tar.gz -C /"

```

### 3. Enable the Health Check in Slurm

Update your `slurm.conf` (typically on your management node/controller) to trigger
NHC automatically.

```bash
HealthCheckProgram=/usr/sbin/nhc
HealthCheckInterval=300
HealthCheckNodeState=ANY

```

### 4. Final Activation

Restart the `slurmd` service on all target nodes to begin the health check cycle.

```bash
clush -w s[1-3] "sudo systemctl restart slurmd"

```

---
