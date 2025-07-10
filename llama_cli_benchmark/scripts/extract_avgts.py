import json
import os
import csv
import re
from pathlib import Path

def parse_filename(filename):
    # Parse filename like bench_(thread_count)t_b(batch_size)_(type).json
    pattern = r'bench_(\d+)t_b(\d+)_?(\w*).json'
    match = re.match(pattern, filename)
    if match:
        thread_count = int(match.group(1))
        batch_size = int(match.group(2))
        type_name = match.group(3) if match.group(3) else "default"
        return thread_count, batch_size, type_name
    # Handle special case for simpler format like bench_8t.json
    pattern2 = r'bench_(\d+)t.json'
    match = re.match(pattern2, filename)
    if match:
        return int(match.group(1)), 1, "default"
    return None

def extract_avg_ts():
    # Get the current directory (scripts directory)
    script_dir = Path(__file__).parent
    
    # Create a list to store results
    results = []
    
    # Iterate through all JSON files in the directory
    for json_file in script_dir.glob('*.json'):
        try:
            filename_parts = parse_filename(json_file.name)
            if filename_parts:
                thread_count, batch_size, type_name = filename_parts
                with open(json_file, 'r') as f:
                    data = json.load(f)
                    
                    # Check if the file contains data and avg_ts
                    if isinstance(data, list) and len(data) > 0 and 'avg_ts' in data[0]:
                        results.append({
                            'thread_count': thread_count,
                            'batch_size': batch_size,
                            'type': type_name,
                            'avg_ts': data[0]['avg_ts']
                        })
        except Exception as e:
            print(f"Error processing {json_file}: {e}")
    
    # Sort results by thread_count, batch_size, and type
    results.sort(key=lambda x: (x['thread_count'], x['batch_size'], x['type']))
    
    # Write results to CSV
    output_file = script_dir.parent / 'data' / 'avg_ts_results.csv'
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['thread_count', 'batch_size', 'type', 'avg_ts'])
        writer.writeheader()
        writer.writerows(results)
    
    print(f"Results have been written to {output_file}")

if __name__ == "__main__":
    extract_avg_ts()
