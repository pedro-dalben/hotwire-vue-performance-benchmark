#!/usr/bin/env python3
import json
import csv
from pathlib import Path

output_dir = Path("docs/results/raw")
aggregated_file = output_dir / "aggregated.json"

lighthouse_summary = {}
k6_summary = {}

if (output_dir / "lighthouse_summary.csv").exists():
    with open(output_dir / "lighthouse_summary.csv", 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = f"{row['app']}_{row['route']}"
            if key not in lighthouse_summary:
                lighthouse_summary[key] = {}
            lighthouse_summary[key][row['metric']] = {
                'median': float(row['median']),
                'p95': float(row['p95'])
            }

if (output_dir / "k6_summary.csv").exists():
    with open(output_dir / "k6_summary.csv", 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = f"{row['app']}_{row['profile']}"
            if key not in k6_summary:
                k6_summary[key] = {}
            k6_summary[key] = {
                'p95': float(row['p95']),
                'p99': float(row['p99']),
                'failed_rate': float(row['failed_rate']),
                'throughput': float(row['throughput'])
            }

aggregated = {
    'lighthouse': lighthouse_summary,
    'k6': k6_summary
}

with open(aggregated_file, 'w') as f:
    json.dump(aggregated, f, indent=2)

print(f"✅ Resultados agregados salvos em {aggregated_file}")

