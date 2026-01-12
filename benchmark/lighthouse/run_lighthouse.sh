#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.."

if [ -f benchmark/.env ]; then
    source benchmark/.env
else
    source benchmark/env.example
fi

OUTPUT_DIR="docs/results/raw"
mkdir -p "$OUTPUT_DIR"

URLS=(
    "http://127.0.0.1:$HOTWIRE_PORT/appointments|hotwire|appointments"
    "http://127.0.0.1:$HOTWIRE_PORT/appointments/1|hotwire|appointments_detail"
    "http://127.0.0.1:$HOTWIRE_PORT/appointments/new|hotwire|appointments_new"
    "http://127.0.0.1:$VUE_PORT/appointments|vue|appointments"
    "http://127.0.0.1:$VUE_PORT/appointments/1|vue|appointments_detail"
    "http://127.0.0.1:$VUE_PORT/appointments/new|vue|appointments_new"
)

echo "=== Executando Lighthouse ==="

for url_spec in "${URLS[@]}"; do
    IFS='|' read -r url app route <<< "$url_spec"

    echo ""
    echo "Testando: $url ($app - $route)"

    for run in {1..5}; do
        echo "  Run $run/5..."
        output_file="$OUTPUT_DIR/lighthouse_${app}_${route}_run${run}.json"

        lighthouse "$url" \
            --config-path="$SCRIPT_DIR/lighthouse.config.js" \
            --output=json \
            --output-path="$output_file" \
            --chrome-flags="--headless --no-sandbox" \
            --quiet || true

        if [ -f "$output_file" ]; then
            python3 << EOF
import json
import sys

try:
    with open('$output_file', 'r') as f:
        data = json.load(f)

    final_url = data.get('finalUrl', '')
    dom_elements = data.get('audits', {}).get('dom-size', {}).get('details', {}).get('items', [])

    if '$app' == 'vue':
        has_marker = False
        for item in dom_elements:
            if 'data-bench-route' in str(item):
                has_marker = True
                break

        if not has_marker:
            print(f"⚠️  Aviso: marcador data-bench-route não encontrado na rota $route")
            sys.exit(1)

    print(f"✅ Run $run concluído")
except Exception as e:
    print(f"❌ Erro ao validar: {e}")
    sys.exit(1)
EOF
        fi
    done
done

echo ""
echo "=== Processando resultados ==="
python3 << 'PYTHON_SCRIPT'
import json
import os
import statistics
from pathlib import Path

output_dir = Path("docs/results/raw")
lighthouse_files = list(output_dir.glob("lighthouse_*.json"))

results = {}

for file in lighthouse_files:
    parts = file.stem.split("_")
    if len(parts) < 4:
        continue

    app = parts[1]
    route = "_".join(parts[2:-1])

    key = f"{app}_{route}"
    if key not in results:
        results[key] = []

    try:
        with open(file, 'r') as f:
            data = json.load(f)

        audits = data.get('audits', {})
        categories = data.get('categories', {})

        performance = categories.get('performance', {}).get('score', 0) * 100

        metrics = {
            'performance_score': performance,
            'fcp': audits.get('first-contentful-paint', {}).get('numericValue', 0),
            'lcp': audits.get('largest-contentful-paint', {}).get('numericValue', 0),
            'tbt': audits.get('total-blocking-time', {}).get('numericValue', 0),
            'speed_index': audits.get('speed-index', {}).get('numericValue', 0),
            'cls': audits.get('cumulative-layout-shift', {}).get('numericValue', 0),
        }

        network_audit = audits.get('network-requests', {})
        if network_audit:
            details = network_audit.get('details', {})
            items = details.get('items', [])

            total_requests = len(items)
            total_transfer_size = sum(item.get('transferSize', 0) for item in items)
            script_transfer_size = sum(
                item.get('transferSize', 0) for item in items
                if item.get('mimeType', '').startswith('application/javascript') or
                   item.get('url', '').endswith('.js')
            )
        else:
            total_requests = 0
            total_transfer_size = 0
            script_transfer_size = 0

        total_byte_weight = audits.get('total-byte-weight', {}).get('numericValue', 0)

        metrics['total_requests'] = total_requests
        metrics['total_transfer_size'] = total_transfer_size
        metrics['script_transfer_size'] = script_transfer_size
        metrics['total_byte_weight'] = total_byte_weight

        results[key].append(metrics)
    except Exception as e:
        print(f"Erro ao processar {file}: {e}")

summary = []
for key, runs in results.items():
    if not runs:
        continue

    app, route = key.split('_', 1)

    for metric_name in ['performance_score', 'fcp', 'lcp', 'tbt', 'speed_index', 'cls',
                        'total_requests', 'total_transfer_size', 'script_transfer_size', 'total_byte_weight']:
        values = [r[metric_name] for r in runs if metric_name in r]
        if values:
            median = statistics.median(values)
            p95 = sorted(values)[int(len(values) * 0.95)] if len(values) > 1 else values[0]

            summary.append({
                'app': app,
                'route': route,
                'metric': metric_name,
                'median': median,
                'p95': p95,
                'runs': len(values)
            })

with open(output_dir / 'lighthouse_summary.csv', 'w') as f:
    f.write('app,route,metric,median,p95,runs\n')
    for row in summary:
        f.write(f"{row['app']},{row['route']},{row['metric']},{row['median']:.2f},{row['p95']:.2f},{row['runs']}\n")

print(f"✅ Resumo salvo em {output_dir / 'lighthouse_summary.csv'}")
PYTHON_SCRIPT

echo ""
echo "✅ Lighthouse concluído!"

