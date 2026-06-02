#!/bin/bash
# load.sh - reusable load generator for the Slurm hands-on exercises.
#
# Submits N single-core sleep jobs as a given user into a given
# partition/QOS so you can watch the queue back up. Each user has a
# DefaultAccount already (set by scripts/create_users_groups.sh), so
# no --account is needed.
#
# usage: load.sh USER COUNT [PARTITION] [QOS]
#
# Lab convention: install this to /root/load.sh on the head node:
#   cp scripts/load.sh /root/load.sh && chmod +x /root/load.sh
#
# Run as root - the script uses 'sudo -u' to submit jobs AS the named
# user so accounting and fairshare attribute correctly.
#
# Examples:
#   /root/load.sh justin 15                          # 15 jobs as justin, lcilab, normal
#   /root/load.sh bob 3                              # 3 jobs as bob
#   /root/load.sh bob 1 lcilab low                   # one low-QOS job (exercise 5)

u=$1; n=$2; part=${3:-lcilab}; qos=${4:-normal}

if [ -z "$u" ] || [ -z "$n" ]; then
  echo "usage: $0 USER COUNT [PARTITION] [QOS]" >&2
  exit 1
fi

# Resolve sbatch to its absolute path. sudo's secure_path
# (/sbin:/bin:/usr/sbin:/usr/bin) does not include Slurm's bin dir, so
# 'sudo -u user sbatch' fails with "command not found". Call it by full
# path to sidestep sudo's sanitized PATH.
sbatch=$(command -v sbatch || echo /opt/slurm/current/bin/sbatch)

for i in $(seq 1 "$n"); do
  sudo -u "$u" "$sbatch" -p "$part" -q "$qos" -n1 \
    --wrap "sleep 600" -J "${u}-${i}" -o /dev/null
done
