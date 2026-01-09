#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -f benchmark/.env ]; then
    source benchmark/.env
else
    source benchmark/env.example
fi

echo "=== Aquecendo aplicações ==="

warmup_url() {
    local url=$1
    local name=$2
    echo "Aquecendo $name..."
    for i in {1..20}; do
        curl -s "$url" > /dev/null 2>&1 || true
    done
    echo "✅ $name aquecido"
}

echo "Hotwire app..."
warmup_url "http://127.0.0.1:$HOTWIRE_PORT/appointments" "Hotwire /appointments"
warmup_url "http://127.0.0.1:$HOTWIRE_PORT/appointments/1" "Hotwire /appointments/1"
warmup_url "http://127.0.0.1:$HOTWIRE_PORT/appointments/new" "Hotwire /appointments/new"

echo ""
echo "Vue app..."
warmup_url "http://127.0.0.1:$VUE_PORT/appointments" "Vue /appointments"
warmup_url "http://127.0.0.1:$VUE_PORT/appointments/1" "Vue /appointments/1"
warmup_url "http://127.0.0.1:$VUE_PORT/appointments/new" "Vue /appointments/new"

echo ""
echo "✅ Warmup concluído!"
