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
    -e HOTWIRE_URL="http://127.0.0.1:$HOTWIRE_PORT" \
    "$SCRIPT_DIR/script_hotwire.js" > "$OUTPUT_DIR/k6_hotwire_${PROFILE}_output.txt" 2>&1

echo ""
echo "Testando API app..."
k6 run \
    --vus "$VUS" \
    --duration 60s \
    -e API_URL="http://127.0.0.1:$API_PORT/api" \
    "$SCRIPT_DIR/script_api.js" > "$OUTPUT_DIR/k6_api_${PROFILE}_output.txt" 2>&1

echo ""
echo "=== Processando resultados ==="
python3 << 'PYTHON_SCRIPT'
import re
from pathlib import Path

output_dir = Path("docs/results/raw")
k6_output_files = list(output_dir.glob("k6_*_output.txt"))

results = []

for file in k6_output_files:
    try:
        with open(file, 'r') as f:
            content = f.read()

        app = 'hotwire' if 'hotwire' in file.stem else 'api'
        profile = 'leve' if 'leve' in file.stem else 'moderado'

        duration_line = re.search(r'http_req_duration[^:]*:.*?p\(95\)=([\d.]+)(\w+)', content, re.DOTALL)
        p99_line = re.search(r'http_req_duration[^:]*:.*?p\(99\)=([\d.]+)(\w+)', content, re.DOTALL)
        failed_match = re.search(r'http_req_failed[^:]*:\s*([\d.]+)%', content)
        throughput_match = re.search(r'http_reqs[^:]*:\s*\d+\s+([\d.]+)/s', content)

        p95 = 0
        if duration_line:
            p95_val = float(duration_line.group(1))
            unit = duration_line.group(2).lower().strip()
            if unit == 's':
                p95 = p95_val * 1000
            elif unit in ['us', 'µs']:
                p95 = p95_val / 1000
            else:
                p95 = p95_val

        p99 = 0
        if p99_line:
            p99_val = float(p99_line.group(1))
            unit = p99_line.group(2).lower().strip()
            if unit == 's':
                p99 = p99_val * 1000
            elif unit in ['us', 'µs']:
                p99 = p99_val / 1000
            else:
                p99 = p99_val

        failed_rate = 0
        if failed_match:
            failed_rate = float(failed_match.group(1)) / 100

        throughput = 0
        if throughput_match:
            throughput = float(throughput_match.group(1))

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
