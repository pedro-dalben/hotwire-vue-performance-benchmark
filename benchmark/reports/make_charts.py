#!/usr/bin/env python3
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

output_dir = Path("docs/results")
charts_dir = output_dir / "charts"
raw_dir = output_dir / "raw"
charts_dir.mkdir(parents=True, exist_ok=True)

aggregated_file = raw_dir / "aggregated.json"

if not aggregated_file.exists():
    print(f"❌ {aggregated_file} não encontrado. Execute aggregate_results.py primeiro.")
    exit(1)

with open(aggregated_file, 'r') as f:
    data = json.load(f)

lighthouse = data.get('lighthouse', {})
k6 = data.get('k6', {})

def create_bar_chart(data_dict, title, ylabel, filename, routes=None):
    if not data_dict:
        return

    apps = []
    values = []
    labels = []

    if routes:
        for route in routes:
            for app in ['hotwire', 'vue']:
                key = f"{app}_{route}"
                if key in data_dict:
                    apps.append(app)
                    values.append(data_dict[key])
                    labels.append(f"{app}\n{route}")
    else:
        for key, value in data_dict.items():
            app, route = key.split('_', 1)
            apps.append(app)
            values.append(value)
            labels.append(f"{app}\n{route}")

    if not values:
        return

    fig, ax = plt.subplots(figsize=(10, 6))
    colors = ['#3b82f6' if app == 'hotwire' else '#10b981' for app in apps]
    bars = ax.bar(range(len(values)), values, color=colors)

    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.set_ylabel(ylabel)
    ax.set_xticks(range(len(labels)))
    ax.set_xticklabels(labels, rotation=45, ha='right')
    ax.grid(axis='y', alpha=0.3)

    for i, (bar, val) in enumerate(zip(bars, values)):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{val:.1f}',
                ha='center', va='bottom')

    plt.tight_layout()
    plt.savefig(charts_dir / filename, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"✅ Gráfico salvo: {filename}")

performance_scores = {}
for key, metrics in lighthouse.items():
    if 'performance' in key.lower() and 'score' in metrics:
        performance_scores[key] = metrics['score']['median']
    elif 'performance_score' in metrics:
        performance_scores[key] = metrics['performance_score']['median']

if performance_scores:
    create_bar_chart(performance_scores, 'Performance Score (Lighthouse)', 'Score', 'performance_score.png')

lcp_values = {}
for key, metrics in lighthouse.items():
    if 'lcp' in metrics:
        lcp_values[key] = metrics['lcp']['median']

if lcp_values:
    create_bar_chart(lcp_values, 'Largest Contentful Paint (LCP)', 'ms', 'lcp.png')

byte_weight = {}
for key, metrics in lighthouse.items():
    if 'total_byte' in key.lower() and 'weight' in metrics:
        byte_weight[key] = metrics['weight']['median'] / 1024
    elif 'total_byte_weight' in metrics:
        byte_weight[key] = metrics['total_byte_weight']['median'] / 1024

if byte_weight:
    create_bar_chart(byte_weight, 'Total Byte Weight', 'KB', 'byte_weight.png')

k6_p95 = {}
for key, metrics in k6.items():
    if 'p95' in metrics:
        k6_p95[key] = metrics['p95']

if k6_p95:
    create_bar_chart(k6_p95, 'k6 Request Duration p95', 'ms', 'k6_p95.png')

print(f"\n✅ Todos os gráficos salvos em {charts_dir}")
