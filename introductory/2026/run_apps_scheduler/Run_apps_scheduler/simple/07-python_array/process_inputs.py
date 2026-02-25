#!/usr/bin/env python3
"""
process_inputs.py - Process input files in a Slurm array job

This script demonstrates how to use SLURM_ARRAY_TASK_ID
to process different input files in parallel array tasks.

Usage: python3 process_inputs.py <array_task_id>
"""

import sys
import os

def process_file(input_file, output_file):
    """Process an input file and write statistics to output file."""
    
    with open(input_file, "r") as f:
        data = f.read()
        numbers = [int(num) for num in data.split()]
    
    if not numbers:
        return "No numbers found in input file"
    
    result = {
        'count': len(numbers),
        'sum': sum(numbers),
        'mean': sum(numbers) / len(numbers),
        'min': min(numbers),
        'max': max(numbers)
    }
    
    with open(output_file, "w") as f:
        f.write(f"Results for {input_file}\n")
        f.write("=" * 40 + "\n")
        f.write(f"Count:  {result['count']}\n")
        f.write(f"Sum:    {result['sum']}\n")
        f.write(f"Mean:   {result['mean']:.2f}\n")
        f.write(f"Min:    {result['min']}\n")
        f.write(f"Max:    {result['max']}\n")
    
    return result

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <array_task_id>")
        print(f"Example: {sys.argv[0]} 1")
        sys.exit(1)
    
    array_task_id = int(sys.argv[1])
    
    input_dir = "input"
    output_dir = "output"
    
    input_file = os.path.join(input_dir, f"{array_task_id}.inp")
    output_file = os.path.join(output_dir, f"{array_task_id}.out")
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        sys.exit(1)
    
    print(f"Processing array task {array_task_id}")
    print(f"  Input:  {input_file}")
    print(f"  Output: {output_file}")
    
    result = process_file(input_file, output_file)
    
    print(f"  Result: Sum={result['sum']}, Count={result['count']}, Mean={result['mean']:.2f}")
    print(f"Task {array_task_id} complete!")
