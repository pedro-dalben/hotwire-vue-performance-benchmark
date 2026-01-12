#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=== Verificando se serviços estão rodando ==="

if [ -f benchmark/.env ]; then
    source benchmark/.env
else
    source benchmark/env.example
fi

check_service() {
    local url=$1
    if curl -s -f "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

if ! check_service "http://127.0.0.1:$HOTWIRE_PORT/up" || \
   ! check_service "http://127.0.0.1:$API_PORT/up" || \
   ! check_service "http://127.0.0.1:$VUE_PORT"; then
    echo "Serviços não estão rodando. Iniciando..."
    "$SCRIPT_DIR/start_all.sh"
    sleep 5
fi

echo ""
echo "=== Executando warmup ==="
"$SCRIPT_DIR/warmup.sh"

echo ""
echo "=== Executando Lighthouse ==="
"$SCRIPT_DIR/lighthouse/run_lighthouse.sh"

echo ""
echo "=== Executando k6 (perfil leve) ==="
"$SCRIPT_DIR/k6/run_k6.sh" leve

echo ""
echo "=== Executando k6 (perfil moderado) ==="
"$SCRIPT_DIR/k6/run_k6.sh" moderado

echo ""
echo "=== Agregando resultados ==="
cd benchmark/reports
python3 aggregate_results.py
python3 make_charts.py
cd ../..

echo ""
echo "=== Gerando relatório ==="
python3 << 'PYTHON_SCRIPT'
import json
import csv
from pathlib import Path
import subprocess
import platform

output_dir = Path("docs/results")
raw_dir = output_dir / "raw"
template_file = Path("benchmark/reports/template_report.md")
report_file = output_dir / "REPORT.md"

def get_version(cmd):
    try:
        result = subprocess.run(cmd.split(), capture_output=True, text=True, timeout=5)
        return result.stdout.strip().split('\n')[0] if result.returncode == 0 else "N/A"
    except:
        return "N/A"

hardware_info = f"{platform.system()} {platform.release()} - {platform.processor()}"
ruby_version = get_version("ruby --version")
node_version = get_version("node --version")
chrome_version = get_version("google-chrome --version") or get_version("chromium --version") or "N/A"
lighthouse_version = get_version("lighthouse --version")
k6_version = get_version("k6 version")

lighthouse_data = {}
if (raw_dir / "lighthouse_summary.csv").exists():
    with open(raw_dir / "lighthouse_summary.csv", 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = f"{row['app']}_{row['route']}"
            if key not in lighthouse_data:
                lighthouse_data[key] = {}
            lighthouse_data[key][row['metric']] = {
                'median': float(row['median']),
                'p95': float(row['p95'])
            }

k6_data = {}
if (raw_dir / "k6_summary.csv").exists():
    with open(raw_dir / "k6_summary.csv", 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = f"{row['app']}_{row['profile']}"
            k6_data[key] = {
                'p95': float(row['p95']),
                'p99': float(row['p99']),
                'failed_rate': float(row['failed_rate']),
                'throughput': float(row['throughput'])
            }

def build_performance_table():
    rows = []
    for route in ['appointments', 'appointments_detail', 'appointments_new']:
        for app in ['hotwire', 'vue']:
            key = f"{app}_{route}"
            if key in lighthouse_data and 'performance_score' in lighthouse_data[key]:
                score = lighthouse_data[key]['performance_score']['median']
                rows.append(f"| {app} | {route} | {score:.1f} |")
    return "\n".join(rows) if rows else "Nenhum dado disponível"

def build_metrics_table():
    rows = []
    metrics = ['lcp', 'fcp', 'tbt', 'speed_index', 'cls']
    for route in ['appointments']:
        for app in ['hotwire', 'vue']:
            key = f"{app}_{route}"
            if key in lighthouse_data:
                row = f"| {app} | {route} |"
                for metric in metrics:
                    if metric in lighthouse_data[key]:
                        row += f" {lighthouse_data[key][metric]['median']:.1f} |"
                    else:
                        row += " N/A |"
                rows.append(row)
    return "\n".join(rows) if rows else "Nenhum dado disponível"

def build_byte_weight_table():
    rows = []
    for route in ['appointments', 'appointments_detail', 'appointments_new']:
        for app in ['hotwire', 'vue']:
            key = f"{app}_{route}"
            if key in lighthouse_data and 'total_byte_weight' in lighthouse_data[key]:
                weight = lighthouse_data[key]['total_byte_weight']['median'] / 1024
                rows.append(f"| {app} | {route} | {weight:.1f} KB |")
    return "\n".join(rows) if rows else "Nenhum dado disponível"

def build_k6_latency_table():
    rows = []
    for profile in ['leve', 'moderado']:
        for app in ['hotwire', 'api']:
            key = f"{app}_{profile}"
            if key in k6_data:
                p95 = k6_data[key]['p95']
                p99 = k6_data[key]['p99']
                rows.append(f"| {app} | {profile} | {p95:.1f} | {p99:.1f} |")
    return "\n".join(rows) if rows else "Nenhum dado disponível"

def build_k6_errors_table():
    rows = []
    for profile in ['leve', 'moderado']:
        for app in ['hotwire', 'api']:
            key = f"{app}_{profile}"
            if key in k6_data:
                failed = k6_data[key]['failed_rate'] * 100
                throughput = k6_data[key]['throughput']
                rows.append(f"| {app} | {profile} | {failed:.2f}% | {throughput:.1f} req/s |")
    return "\n".join(rows) if rows else "Nenhum dado disponível"

def build_complexity_table():
    rows = []
    try:
        hotwire_gems = len(open("apps/hotwire_app/Gemfile.lock").readlines()) if Path("apps/hotwire_app/Gemfile.lock").exists() else 0
        api_gems = len(open("apps/api_app/Gemfile.lock").readlines()) if Path("apps/api_app/Gemfile.lock").exists() else 0
        vue_deps = 0
        if Path("apps/vue_app/package-lock.json").exists():
            import json
            with open("apps/vue_app/package-lock.json") as f:
                vue_deps = len(json.load(f).get('packages', {}))

        rows.append(f"| hotwire_app | {hotwire_gems} gems | - |")
        rows.append(f"| api_app | {api_gems} gems | - |")
        rows.append(f"| vue_app | - | {vue_deps} npm packages |")
    except:
        rows.append("| Erro ao calcular | | |")

    return "\n".join(rows) if rows else "Nenhum dado disponível"

with open(template_file, 'r') as f:
    template = f.read()

report = template.replace("{{HARDWARE_INFO}}", hardware_info)
report = report.replace("{{RUBY_VERSION}}", ruby_version)
report = report.replace("{{NODE_VERSION}}", node_version)
report = report.replace("{{CHROME_VERSION}}", chrome_version)
report = report.replace("{{LIGHTHOUSE_VERSION}}", lighthouse_version)
report = report.replace("{{K6_VERSION}}", k6_version)
report = report.replace("{{LIGHTHOUSE_PERFORMANCE_TABLE}}", build_performance_table())
report = report.replace("{{LIGHTHOUSE_METRICS_TABLE}}", build_metrics_table())
report = report.replace("{{BYTE_WEIGHT_TABLE}}", build_byte_weight_table())
report = report.replace("{{K6_LATENCY_TABLE}}", build_k6_latency_table())
report = report.replace("{{K6_ERRORS_TABLE}}", build_k6_errors_table())
report = report.replace("{{COMPLEXITY_TABLE}}", build_complexity_table())

with open(report_file, 'w') as f:
    f.write(report)

print(f"✅ Relatório gerado em {report_file}")
PYTHON_SCRIPT

echo ""
echo "✅ Benchmark completo!"
echo "Relatório disponível em: docs/results/REPORT.md"

