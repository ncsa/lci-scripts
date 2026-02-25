#!/usr/bin/env python3
"""
generate_inputs.py - Generate sample input files for array job demo

Creates numbered input files (1.inp, 2.inp, etc.)
Each file contains random integers for processing.
"""

import os
import random

def generate_inputs(num_files=5, input_dir="input"):
    """Generate sample input files."""
    
    os.makedirs(input_dir, exist_ok=True)
    os.makedirs("output", exist_ok=True)
    
    random.seed(42)  # Reproducible results
    
    for i in range(1, num_files + 1):
        filename = os.path.join(input_dir, f"{i}.inp")
        numbers = [str(random.randint(1, 100)) for _ in range(random.randint(5, 15))]
        
        with open(filename, "w") as f:
            f.write(" ".join(numbers))
        
        print(f"Created {filename} with {len(numbers)} numbers")
    
    print(f"\nGenerated {num_files} input files in {input_dir}/")
    print(f"Output will be written to output/")

if __name__ == "__main__":
    generate_inputs()
