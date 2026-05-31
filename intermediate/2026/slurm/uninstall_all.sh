#!/bin/bash
# ============================================================
# uninstall_all.sh - undo everything install_all.sh installed.
#
# Runs the Slurm destroy playbook (stops slurmctld/slurmdbd/slurmd
# on head + compute, removes /opt/slurm, /etc/slurm, MUNGE, the
# slurm user/group, drops the slurm_acct_db database, and removes
# the slurmd configless conf-cache on compute nodes) and then the
# head_node destroy playbook (removes MariaDB + lab packages and
# /var/lib/mysql, disables CRB/powertools).
#
# Works for BOTH install modes:
#   - classic    (./install_all.sh XX)
#   - configless (./install_all.sh --configless XX)
# The destroy plays target services, files, packages, users, and
# directories; they do not care whether slurm.conf was written
# locally on compute nodes or fetched from the controller at
# slurmd startup. The extra conf-cache sweep below is a belt-and-
# suspenders pass so the cached copy of slurm.conf that 'slurmd
# --conf-server' writes under SlurmdSpoolDir is gone for sure.
#
# Operates on the working copies install_all.sh wrote to
# ~/slurm and ~/head_node. After both destroy plays succeed,
# those working directories are removed so the next install runs
# from a clean state.
#
# Usage (run as root on lci-head-XX-1):
#   ./uninstall_all.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEAD_DST="${HOME}/head_node"
SCHED_DST="${HOME}/slurm"

# --- Must be root (destroy plays manage services and packages). ---
if [ "${EUID}" -ne 0 ]; then
  echo "ERROR: run this script as root on the head node (e.g. 'sudo -i' first)." >&2
  exit 1
fi

# --- Figure out what's actually here. We don't require BOTH to be
#     present any more - a half-installed cluster should still be
#     cleanable. We just need at least one of them.
have_sched=false; have_head=false
[ -d "${SCHED_DST}" ] && have_sched=true
[ -d "${HEAD_DST}" ]  && have_head=true

if ! ${have_sched} && ! ${have_head}; then
  echo
  echo "Neither ~/slurm nor ~/head_node exists - install_all.sh may not"
  echo "have run, or this has already been cleaned up. Nothing to do." >&2
  exit 1
fi

# --- Heuristic: detect whether the slurm install was configless.
#     The marker is 'SlurmctldParameters=enable_configless' in the
#     head's slurm.conf AND the absence of /etc/slurm/slurm.conf on
#     compute nodes. We can detect the first one cheaply if the
#     working dir is still here.
CONFIGLESS_DETECTED=false
if ${have_sched} && grep -q '^SlurmctldParameters=enable_configless' \
   "${SCHED_DST}/roles/slurm-source/templates/slurm.conf.j2" 2>/dev/null; then
  # The template *always* has this line in the current bundle; the real
  # signal is whether compute nodes lack a local slurm.conf. Check one.
  if [ -f "${SCHED_DST}/hosts.ini" ]; then
    first_compute=$(awk '/^\[all_nodes\]/{flag=1;next}/^\[/{flag=0}flag && NF{print $1; exit}' \
                    "${SCHED_DST}/hosts.ini" 2>/dev/null || true)
    if [ -n "${first_compute}" ]; then
      if ssh -o BatchMode=yes -o ConnectTimeout=5 "${first_compute}" \
         'test ! -e /etc/slurm/slurm.conf' 2>/dev/null; then
        CONFIGLESS_DETECTED=true
      fi
    fi
  fi
fi

echo ">>> Detected install mode: $(${CONFIGLESS_DETECTED} && echo configless || echo classic)"

# ============================================================
# Step 1: Tear down Slurm (head + compute)
# ============================================================
if ${have_sched}; then
  echo
  echo "============================================================"
  echo ">>> STEP 1/3: Slurm scheduler teardown"
  echo "============================================================"
  cd "${SCHED_DST}"
  ansible-playbook -i hosts.ini destroy.yml
  SCHED_RC=$?
  if [ "${SCHED_RC}" -ne 0 ]; then
    echo "WARNING: slurm destroy.yml exited with ${SCHED_RC} - continuing anyway." >&2
  fi
else
  echo ">>> Skipping Slurm teardown (~/slurm not present)."
fi

# ============================================================
# Step 2: Belt-and-suspenders sweep for configless conf-cache.
#
# slurmd --conf-server caches the fetched config under SlurmdSpoolDir
# (default /var/spool/slurmd). The destroy play removes
# /var/spool/slurmd.spool (this lab's SlurmdSpoolDir), but in case
# anyone changes that path or the spool dir survived for some other
# reason, blow away the cache explicitly on each compute node.
# ============================================================
if ${have_sched} && [ -f "${SCHED_DST}/hosts.ini" ]; then
  echo
  echo "============================================================"
  echo ">>> STEP 2/3: Sweep configless conf-cache on compute nodes"
  echo "============================================================"
  compute_nodes=$(awk '/^\[all_nodes\]/{flag=1;next}/^\[/{flag=0}flag && NF{print $1}' \
                  "${SCHED_DST}/hosts.ini" 2>/dev/null || true)
  for cn_host in ${compute_nodes}; do
    echo ">>> ${cn_host}: removing conf-cache + any stray slurm.conf"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "${cn_host}" '
      rm -rf /var/spool/slurmd/conf-cache \
             /var/spool/slurmd.spool/conf-cache \
             /var/spool/slurmd \
             /etc/slurm/slurm.conf
    ' 2>/dev/null || echo "    (ssh to ${cn_host} failed - skipping)"
  done
else
  echo ">>> Skipping conf-cache sweep (no hosts.ini available)."
fi

# ============================================================
# Step 3: Tear down head node base config (MariaDB, lab packages)
# ============================================================
if ${have_head}; then
  echo
  echo "============================================================"
  echo ">>> STEP 3/3: Head node base teardown"
  echo "============================================================"
  cd "${HEAD_DST}"
  ansible-playbook destroy.yml
  HEAD_RC=$?
  if [ "${HEAD_RC}" -ne 0 ]; then
    echo "WARNING: head_node destroy.yml exited with ${HEAD_RC} - continuing anyway." >&2
  fi
else
  echo ">>> Skipping head_node teardown (~/head_node not present)."
fi

# ============================================================
# Step 4: Remove the working copies install_all.sh placed in $HOME
# ============================================================
echo
echo ">>> Removing working copies in ${HOME}..."
cd "${HOME}"
rm -rf "${SCHED_DST}" "${HEAD_DST}"

# ============================================================
# Done
# ============================================================
echo
echo "============================================================"
echo ">>> Uninstall complete."
echo "============================================================"
echo "Re-run the installer from this bundle with one of:"
echo "    ${SCRIPT_DIR}/install_all.sh <cluster_number>"
echo "    ${SCRIPT_DIR}/install_all.sh --configless <cluster_number>"
