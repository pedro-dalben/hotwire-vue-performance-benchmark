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

PROFILE=${1:-leve}
VUS=${2:-20}

if [ "$PROFILE" = "moderado" ]; then
    VUS=50
fi

echo "=== Executando k6 - Perfil: $PROFILE (VUs: $VUS) ==="

echo ""
echo "Testando Hotwire app..."
k6 run \
    --vus "$VUS" \
    --duration 60s \
    --out json="$OUTPUT_DIR/k6_hotwire_${PROFILE}.json" \
    -e HOTWIRE_URL="http://127.0.0.1:$HOTWIRE_PORT" \
    "$SCRIPT_DIR/script_hotwire.js"

echo ""
echo "Testando API app..."
k6 run \
    --vus "$VUS" \
    --duration 60s \
    --out json="$OUTPUT_DIR/k6_api_${PROFILE}.json" \
    -e API_URL="http://127.0.0.1:$API_PORT/api" \
    "$SCRIPT_DIR/script_api.js"

echo ""
echo "=== Processando resultados ==="
python3 << 'PYTHON_SCRIPT'
import json
import os
from pathlib import Path

output_dir = Path("docs/results/raw")
k6_files = list(output_dir.glob("k6_*.json"))

results = []

for file in k6_files:
    try:
        with open(file, 'r') as f:
            data = json.load(f)

        app = 'hotwire' if 'hotwire' in file.stem else 'api'
        profile = 'leve' if 'leve' in file.stem else 'moderado'

        metrics = data.get('metrics', {})

        http_req_duration = metrics.get('http_req_duration', {})
        http_req_failed = metrics.get('http_req_failed', {})
        http_reqs = metrics.get('http_reqs', {})

        p95 = http_req_duration.get('values', {}).get('p(95)', 0)
        p99 = http_req_duration.get('values', {}).get('p(99)', 0)
        failed_rate = http_req_failed.get('values', {}).get('rate', 0)
        throughput = http_reqs.get('values', {}).get('rate', 0)

        results.append({
            'app': app,
            'profile': profile,
            'p95': p95,
            'p99': p99,
            'failed_rate': failed_rate,
            'throughput': throughput
        })
    except Exception as e:
        print(f"Erro ao processar {file}: {e}")

with open(output_dir / 'k6_summary.csv', 'w') as f:
    f.write('app,profile,p95,p99,failed_rate,throughput\n')
    for row in results:
        f.write(f"{row['app']},{row['profile']},{row['p95']:.2f},{row['p99']:.2f},{row['failed_rate']:.4f},{row['throughput']:.2f}\n")

print(f"✅ Resumo salvo em {output_dir / 'k6_summary.csv'}")
PYTHON_SCRIPT

echo ""
echo "✅ k6 concluído!"
