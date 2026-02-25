#!/usr/bin/env Rscript
# process_data.R - Simple R script for Slurm job array
# Demonstrates using SLURM_ARRAY_TASK_ID in R

# Get the array task ID from environment variable
array_task_id <- Sys.getenv("SLURM_ARRAY_TASK_ID")
hostname <- Sys.getenv("HOSTNAME")

# Convert to numeric
task_id <- as.numeric(array_task_id)

# Simple computation example
set.seed(task_id * 42)
data <- rnorm(100, mean = task_id, sd = 1)

result <- data.frame(
  task_id = task_id,
  hostname = hostname,
  mean = mean(data),
  sd = sd(data),
  min = min(data),
  max = max(data)
)

# Write output
output_file <- paste0("output/r_result_", task_id, ".csv")
write.csv(result, output_file, row.names = FALSE)

cat(sprintf("Task %s completed on %s\n", array_task_id, hostname))
cat(sprintf("Output written to %s\n", output_file))
