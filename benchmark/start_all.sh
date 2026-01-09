#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -f benchmark/.env ]; then
    source benchmark/.env
else
    source benchmark/env.example
fi

mkdir -p benchmark/.pids benchmark/.logs

echo "=== Iniciando serviços ==="

echo "Iniciando Hotwire app na porta $HOTWIRE_PORT..."
cd apps/hotwire_app
RAILS_ENV=production RAILS_LOG_TO_STDOUT=true RAILS_LOG_LEVEL=warn \
  bundle exec rails server -p "$HOTWIRE_PORT" -b 127.0.0.1 > ../../benchmark/.logs/hotwire.log 2>&1 &
echo $! > ../../benchmark/.pids/hotwire.pid
cd ../..

echo "Iniciando API app na porta $API_PORT..."
cd apps/api_app
RAILS_ENV=production RAILS_LOG_TO_STDOUT=true RAILS_LOG_LEVEL=warn \
  bundle exec rails server -p "$API_PORT" -b 127.0.0.1 > ../../benchmark/.logs/api.log 2>&1 &
echo $! > ../../benchmark/.pids/api.pid
cd ../..

echo "Build do Vue app..."
cd apps/vue_app
npm run build
cd ../..

echo "Iniciando Vue app na porta $VUE_PORT..."
cd apps/vue_app
npm run preview > ../../benchmark/.logs/vue.log 2>&1 &
echo $! > ../../benchmark/.pids/vue.pid
cd ../..

echo ""
echo "=== Aguardando healthchecks ==="

wait_for_url() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo "✅ $name está respondendo"
            return 0
        fi
        echo "⏳ Aguardando $name... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "❌ $name não respondeu após $max_attempts tentativas"
    return 1
}

wait_for_url "http://127.0.0.1:$HOTWIRE_PORT/up" "Hotwire app"
wait_for_url "http://127.0.0.1:$API_PORT/up" "API app"
wait_for_url "http://127.0.0.1:$VUE_PORT" "Vue app"

echo ""
echo "✅ Todos os serviços estão rodando!"
echo "PIDs salvos em benchmark/.pids/"
echo "Logs salvos em benchmark/.logs/"
