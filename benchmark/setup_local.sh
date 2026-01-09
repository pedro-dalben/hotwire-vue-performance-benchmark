#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=== Verificando dependências ==="

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 não encontrado"
        return 1
    else
        echo "✅ $1 encontrado"
        return 0
    fi
}

MISSING=0

check_command ruby || MISSING=1
check_command bundler || MISSING=1
check_command node || MISSING=1
check_command npm || MISSING=1
check_command psql || MISSING=1
check_command python3 || MISSING=1

if ! check_command k6; then
    echo "⚠️  k6 não encontrado. Instale com: sudo apt-get install k6 (opcional para benchmark)"
fi

if ! check_command lighthouse; then
    echo "⚠️  lighthouse não encontrado. Instale com: npm install -g lighthouse (opcional para benchmark)"
fi

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "Por favor, instale as dependências faltantes antes de continuar."
    exit 1
fi

echo ""
echo "=== Carregando variáveis de ambiente ==="
if [ -f benchmark/.env ]; then
    source benchmark/.env
    echo "✅ .env carregado"
else
    if [ -f benchmark/env.example ]; then
        cp benchmark/env.example benchmark/.env
        echo "✅ Criado .env a partir de env.example"
        source benchmark/.env
    else
        echo "⚠️  benchmark/env.example não encontrado, usando valores padrão"
        export HOTWIRE_PORT=3100
        export API_PORT=3200
        export VUE_PORT=3300
        export HOTWIRE_DB=hotwire_bench
        export API_DB=api_bench
        export PGUSER=${PGUSER:-postgres}
        export PGPASSWORD=${PGPASSWORD:-}
        export PGHOST=${PGHOST:-localhost}
        export PGPORT=${PGPORT:-5432}
    fi
fi

echo ""
echo "=== Gerando seed_data.json ==="
cd benchmark
python3 generate_seed_data.py
cd ..

echo ""
echo "=== Criando databases ==="
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -c "DROP DATABASE IF EXISTS $HOTWIRE_DB;" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -c "CREATE DATABASE $HOTWIRE_DB;" || true

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -c "DROP DATABASE IF EXISTS $API_DB;" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -c "CREATE DATABASE $API_DB;" || true

echo ""
echo "=== Instalando dependências Rails ==="
cd apps/hotwire_app
bundle install
cd ../api_app
bundle install
cd ../..

echo ""
echo "=== Instalando dependências Vue ==="
cd apps/vue_app
npm install
cd ../..

echo ""
echo "=== Rodando migrations ==="
cd apps/hotwire_app
RAILS_ENV=production bundle exec rails db:migrate
cd ../api_app
RAILS_ENV=production bundle exec rails db:migrate
cd ../..

echo ""
echo "=== Rodando seeds ==="
cd apps/hotwire_app
RAILS_ENV=production bundle exec rails db:seed
cd ../api_app
RAILS_ENV=production bundle exec rails db:seed
cd ../..

echo ""
echo "=== Precompilando assets ==="
cd apps/hotwire_app
RAILS_ENV=production bundle exec rails assets:precompile
cd ../..

echo ""
echo "✅ Setup concluído!"
