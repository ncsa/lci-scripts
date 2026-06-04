#!/bin/bash

# verify ollama module is loaded
module_name="ollama"

if module list 2>&1 | grep -q "$module_name"; then
    echo "$module_name is loaded, proceeding with the script..."
else
    echo "$module_name is not loaded. Exiting script."
    exit 1
fi

# Get the hostname
HOSTNAME=$(hostname)

# Check if hostname contains "login"
if [[ $HOSTNAME == *"login"* ]]; then
    echo "Cannot run on $HOSTNAME, please start on a non login node."
    exit 1
else
    # Start your application here
    echo "Starting Ollama serve..."
    # Example: my_app
    nohup ollama serve > /dev/null 2>&1 &
fi

# Start OLLAMA server
# nohup ollama serve > /scratch/$USER/nohup2.out &
# nohup ollama serve > /dev/null 2>&1 &


# Keep the session open until the terminal is closed
exec 9<>/dev/null
#OLLAMA_PID=$!
#trap 'kill -9 $OLLAMA_PID' EXIT
