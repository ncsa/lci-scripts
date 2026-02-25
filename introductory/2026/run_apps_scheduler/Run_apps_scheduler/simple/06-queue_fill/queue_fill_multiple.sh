#!/bin/bash
# Submit multiple jobs to fill the queue

echo "Submitting 6 jobs to fill the queue..."
for i in {1..6}; do
    sbatch queue_fill_batch.sh
done

echo ""
echo "Checking queue status..."
squeue

echo ""
echo "Jobs are now pending/running. Use 'squeue' to monitor."
echo "Use 'scancel -j <jobid>' to cancel specific jobs"
echo "Use 'scancel -u $USER' to cancel all your jobs"
