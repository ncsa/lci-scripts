#!/bin/bash
# ============================================================
# install_all.sh - one-command cluster install for the
#                  intermediate Schedulers track.
#
# Runs the head_node playbook (CRB, timesync, packages) and then
# the scheduler_installation playbook (builds Slurm from source,
# deploys to compute nodes).
#
# NOTE: this variant does NOT configure storage - the Chosen Storage
# Solution is built in a previous lab. See Storage-options.md for where
# to run the lab from.
#
# The Schedulers course focuses on CONFIGURATION and USAGE, not
# installation, so this gets you to a working cluster fast. The
# manual config/usage steps (ClusterShell, users, central
# logging, Slurm usage) are in the sibling 'commands' file.
#
# Usage (run as root on lci-head-XX-1):
#   ./install_all.sh <cluster_number>                e.g. ./install_all.sh 07
#   ./install_all.sh --configless <cluster_number>   configless slurm variant
#   ./install_all.sh                                 (will prompt for cluster number)
#
# --configless: tell the playbook to skip writing /etc/slurm/slurm.conf on
# the compute nodes. The head node already advertises
# 'SlurmctldParameters=enable_configless' and slurmd is launched with
# '--conf-server lci-head-XX-1', so in configless mode compute nodes fetch
# slurm.conf from the controller at slurmd startup instead of reading a
# local file. (The classic install writes /etc/slurm/slurm.conf on every
# compute node; behavior of slurmd is otherwise identical between modes.)
# ============================================================

set -euo pipefail

# --- Parse optional flags. Currently only --configless. -----------
CONFIGLESS=false
ARGS=()
for arg in "$@"; do
  case "${arg}" in
    --configless) CONFIGLESS=true ;;
    -h|--help)
      sed -n '2,21p' "$0"; exit 0 ;;
    --*) echo "ERROR: unknown flag '${arg}'" >&2; exit 1 ;;
    *)   ARGS+=("${arg}") ;;
  esac
done
set -- "${ARGS[@]}"

# --- Resolve this script's directory so it can find the source
#     playbooks regardless of where it's invoked from. ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEAD_SRC="${SCRIPT_DIR}/head_node"
SCHED_SRC="${SCRIPT_DIR}/slurm"

HEAD_DST="${HOME}/head_node"
SCHED_DST="${HOME}/slurm"

# --- Must be root (playbooks become root locally and over SSH). ---
if [ "${EUID}" -ne 0 ]; then
  echo "ERROR: run this script as root on the head node (e.g. 'sudo -i' first)." >&2
  exit 1
fi

# --- Cluster number: arg or prompt. Validate and zero-pad to 2 digits. ---
CN="${1:-}"
if [ -z "${CN}" ]; then
  read -r -p "Enter your cluster number (01-40): " CN
fi
if ! [[ "${CN}" =~ ^[0-9]{1,2}$ ]]; then
  echo "ERROR: cluster number must be 1-2 digits (e.g. 7 or 07)." >&2
  exit 1
fi
printf -v CN '%02d' "$((10#${CN}))"   # 10# avoids octal on leading-zero input
echo ">>> Using cluster number: ${CN}"
echo ">>> Configless mode:     ${CONFIGLESS}"

# --- Sanity-check the source playbooks exist. ---
for d in "${HEAD_SRC}" "${SCHED_SRC}"; do
  if [ ! -d "${d}" ]; then
    echo "ERROR: expected playbook directory not found: ${d}" >&2
    exit 1
  fi
done

# ============================================================
# Step 1: Head node + compute node base configuration
# ============================================================
echo
echo "============================================================"
echo ">>> STEP 1/2: Head node + compute base config"
echo "============================================================"

# Fresh copy in $HOME so re-runs never carry stale substitutions.
rm -rf "${HEAD_DST}"
cp -a "${HEAD_SRC}" "${HEAD_DST}"

# Patch cluster number. All XX live inside lci-*-XX-* hostnames, so
# anchoring on '-XX-' is unambiguous and leaves everything else alone.
sed -i "s/-XX-/-${CN}-/g" "${HEAD_DST}/hosts.ini"

cd "${HEAD_DST}"
echo ">>> Installing ansible-core on head + compute nodes..."
bash installansible.sh
echo ">>> Running head node playbook..."
ansible-playbook playbook.yml

# ============================================================
# Step 2: Slurm scheduler (build from source + deploy)
# ============================================================
echo
echo "============================================================"
echo ">>> STEP 2/2: Slurm scheduler install"
echo "============================================================"

rm -rf "${SCHED_DST}"
cp -a "${SCHED_SRC}" "${SCHED_DST}"

sed -i "s/-XX-/-${CN}-/g" "${SCHED_DST}/hosts.ini"
# cluster_params.yml ships 'cluster_number: 01' (not XX) - patch the key directly.
sed -i "s/^cluster_number:.*/cluster_number: '${CN}'/" \
  "${SCHED_DST}/group_vars/cluster_params.yml"

cd "${SCHED_DST}"
echo ">>> Building and deploying Slurm (this takes a few minutes)..."
ansible-playbook -i hosts.ini -e "configless=${CONFIGLESS}" playbook.yml

# ============================================================
# Step 2b: Ensure /opt/slurm is traversable by all users
# ============================================================
# All users (bob, alice, ... created in the lab) must be able to traverse
# into /opt/slurm/current/bin to run srun/sbatch/etc. In practice only the
# top-level /opt/slurm is the bottleneck: the Slurm build creates
# /opt/slurm/current and .../bin already traversable (0755), so opening up
# /opt/slurm alone is enough for everyone to reach the binaries. The
# playbook now creates /opt/slurm 0755 on both head and compute, so this is
# normally a no-op - but we re-assert it here so the wrapper also
# self-heals a cluster built before that fix (where /opt/slurm was 0750 and
# only slurm + the 'rocky' group could enter, giving everyone else
# "Permission denied").
echo
echo ">>> Ensuring /opt/slurm is 0755 (all users) on head + compute..."
chmod 0755 /opt/slurm                                  # head node (local)
ansible all_nodes -i hosts.ini -m file \
  -a "path=/opt/slurm mode=0755 state=directory"       # compute nodes

# ============================================================
# Done
# ============================================================
echo
echo "============================================================"
echo ">>> Install complete for cluster ${CN}."
echo "============================================================"
echo
echo "IMPORTANT - activate the Slurm commands on PATH:"
echo "  The install wrote /etc/profile.d/slurm.sh (puts"
echo "  /opt/slurm/current/bin and .../sbin on PATH), but profile.d is only"
echo "  sourced by *login* shells - this root shell predates the install, so"
echo "  sinfo/sacctmgr/slurmctld/etc are NOT on PATH yet. Do ONE of:"
echo "    source /etc/profile.d/slurm.sh    # this shell, right now"
echo "    exit; sudo -i                     # or get a fresh login shell"
echo
echo "Verify the scheduler:"
echo "    sinfo"
echo "    systemctl status slurmctld slurmdbd"
echo "    ssh lci-compute-${CN}-1 systemctl status slurmd"
if [ "${CONFIGLESS}" = "true" ]; then
  echo
  echo "Configless check - compute nodes should NOT have a local slurm.conf"
  echo "(slurmd fetched it from the controller at startup):"
  echo "    ssh lci-compute-${CN}-1 ls -l /etc/slurm/slurm.conf   # expect: No such file"
  echo "    ssh lci-compute-${CN}-1 scontrol show config | head"
fi
echo
echo "Next, do the configuration + usage steps by hand - see:"
echo "    ${SCRIPT_DIR}/commands"
echo "(ClusterShell, users/groups, central logging, running jobs.)"
echo
echo "To tear down and re-run:"
echo "    cd ${SCHED_DST} && ansible-playbook -i hosts.ini destroy.yml"
echo "    cd ${HEAD_DST}  && ansible-playbook destroy.yml"
