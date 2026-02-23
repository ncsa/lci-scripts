#!/bin/bash

cmd='sudo dnf install -y ansible-core'

# Install on head node (localhost)
eval ${cmd}

# Install on compute nodes from hosts.ini
# Extract hosts from [all_nodes] section, excluding the section header
hosts=$(awk '/^\[all_nodes\]/{found=1; next} /^\[/{found=0} found && NF' hosts.ini)

for i in $hosts; do
  ssh $i ${cmd}
done
