#!/bin/bash
# count.sh - A simple script that counts from 1 to a given number
# Usage: ./count.sh [number]
# Default: counts to 10 if no argument provided

MAX=${1:-10}

echo "Counting from 1 to $MAX on host $(hostname)"
echo "Started at: $(date)"
echo "---"

for i in $(seq 1 $MAX); do
    echo "$i"
    sleep 1
done

echo "---"
echo "Finished at: $(date)"
