#!/bin/bash
# ============================================================
# create_users_groups.sh - create the 4 departments x 2 users
#   used by the Slurm hands-on exercises, on the head node and
#   all compute nodes, plus the matching Slurm accounting tree.
#
# This automates section 2 of the sibling 'commands' file:
#   - 4 Linux groups (departments) + 8 users (2 per dept)
#   - propagated to compute nodes via ClusterShell (clush -g compute)
#   - 4 Slurm accounts + 8 Slurm users via sacctmgr
#
#   Department  Group     GID    Users (UID)
#   ----------  --------  -----  -------------------------
#   biology     lci-bio   3001   bob (2002),    alice (2003)
#   engineering lci-eng   3002   justin (2004), katie (2005)
#   chemistry   lci-chem  3003   carol (2006),  dave  (2007)
#   physics     lci-phys  3004   erin (2008),   frank (2009)
#
# Idempotent: safe to re-run. Existing groups/users/accounts are
# left in place (the script skips what already exists).
#
# Prereqs: run as root on lci-head-XX-1, ClusterShell configured
# with a 'compute' group (see section 1 of 'commands'), and - for
# the Slurm accounting step - slurmctld/slurmdbd up (sinfo works).
#
# Usage (run as root on the head node):
#   ./create_users_groups.sh             # Linux users/groups + Slurm accounts
#   ./create_users_groups.sh --no-slurm  # Linux users/groups only
# ============================================================

set -euo pipefail

DO_SLURM=1
if [ "${1:-}" = "--no-slurm" ]; then
  DO_SLURM=0
fi

# --- Must be root (useradd/groupadd locally and over clush). ---
if [ "${EUID}" -ne 0 ]; then
  echo "ERROR: run this script as root on the head node (e.g. 'sudo -i' first)." >&2
  exit 1
fi

# --- group_name:gid  and  user_name:uid:group_name tables. ---
GROUPS_TABLE=(
  "lci-bio:3001"
  "lci-eng:3002"
  "lci-chem:3003"
  "lci-phys:3004"
)

# user:uid:linux_group:slurm_account
USERS_TABLE=(
  "bob:2002:lci-bio:biology"
  "alice:2003:lci-bio:biology"
  "justin:2004:lci-eng:engineering"
  "katie:2005:lci-eng:engineering"
  "carol:2006:lci-chem:chemistry"
  "dave:2007:lci-chem:chemistry"
  "erin:2008:lci-phys:physics"
  "frank:2009:lci-phys:physics"
)

# --- Helper: run a command on all compute nodes via ClusterShell. ---
have_clush=1
if ! command -v clush >/dev/null 2>&1; then
  have_clush=0
  echo "WARNING: clush not found - groups/users will be created on the HEAD"
  echo "         node only. Install ClusterShell and re-run, or create them on"
  echo "         the compute nodes by hand (see section 1 of 'commands')." >&2
fi

# ============================================================
# Step 1: Linux groups
# ============================================================
echo "============================================================"
echo ">>> STEP 1: Linux groups"
echo "============================================================"
for entry in "${GROUPS_TABLE[@]}"; do
  g="${entry%%:*}"
  gid="${entry##*:}"

  # Head node (idempotent: skip if the group already exists).
  if getent group "${g}" >/dev/null; then
    echo "    [head]    group ${g} already exists - skipping"
  else
    groupadd -g "${gid}" "${g}"
    echo "    [head]    created group ${g} (gid ${gid})"
  fi

  # Compute nodes. '|| true' so an already-present group elsewhere
  # doesn't abort the run under set -e.
  if [ "${have_clush}" -eq 1 ]; then
    clush -g compute "getent group ${g} >/dev/null || groupadd -g ${gid} ${g}" || true
    echo "    [compute] ensured group ${g} (gid ${gid})"
  fi
done

# ============================================================
# Step 2: Linux users
# ============================================================
echo "============================================================"
echo ">>> STEP 2: Linux users"
echo "============================================================"
for entry in "${USERS_TABLE[@]}"; do
  IFS=: read -r u uid g _acct <<<"${entry}"

  if id "${u}" >/dev/null 2>&1; then
    echo "    [head]    user ${u} already exists - skipping"
  else
    useradd -u "${uid}" -g "${g}" "${u}"
    echo "    [head]    created user ${u} (uid ${uid}, group ${g})"
  fi

  if [ "${have_clush}" -eq 1 ]; then
    clush -g compute "id ${u} >/dev/null 2>&1 || useradd -u ${uid} -g ${g} ${u}" || true
    echo "    [compute] ensured user ${u} (uid ${uid}, group ${g})"
  fi
done

# ============================================================
# Step 3: Slurm accounting tree (accounts + users)
# ============================================================
if [ "${DO_SLURM}" -eq 0 ]; then
  echo "============================================================"
  echo ">>> STEP 3: Slurm accounts SKIPPED (--no-slurm)"
  echo "============================================================"
else
  echo "============================================================"
  echo ">>> STEP 3: Slurm accounting tree"
  echo "============================================================"

  if ! command -v sacctmgr >/dev/null 2>&1; then
    echo "ERROR: sacctmgr not found. Is Slurm on PATH? (try: . /etc/profile.d/*slurm* )" >&2
    echo "       Skipping the Slurm step; re-run after Slurm is installed, or use" >&2
    echo "       --no-slurm to suppress this." >&2
    exit 1
  fi
  if ! sinfo >/dev/null 2>&1; then
    echo "ERROR: 'sinfo' failed - slurmctld may be down. Start it and re-run," >&2
    echo "       or use --no-slurm to create only the Linux users/groups." >&2
    exit 1
  fi

  # Accounts (one per department). sacctmgr -i = non-interactive.
  # 'sacctmgr add' is a no-op if the account already exists.
  for acct in biology engineering chemistry physics; do
    sacctmgr -i add account "${acct}" \
      Description="${acct} dept" Organization=lci || true
    echo "    account ${acct} ensured"
  done

  # Users into their default account.
  for entry in "${USERS_TABLE[@]}"; do
    IFS=: read -r u _uid _g acct <<<"${entry}"
    sacctmgr -i add user "${u}" Account="${acct}" DefaultAccount="${acct}" || true
    echo "    slurm user ${u} -> account ${acct}"
  done
fi

# ============================================================
# Done - verify
# ============================================================
echo "============================================================"
echo ">>> Done. Verification:"
echo "============================================================"
echo "Linux groups (head):"
getent group lci-bio lci-eng lci-chem lci-phys || true
echo
echo "Sample ids (head):"
id bob || true
id katie || true
if [ "${have_clush}" -eq 1 ]; then
  echo
  echo "Compute-node check:"
  clush -g compute "id bob" || true
fi
if [ "${DO_SLURM}" -eq 1 ]; then
  echo
  echo "Slurm accounting tree:"
  sacctmgr show assoc format=Account,User,Share,QOS || true
fi
