#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"

echo "=== Parando serviços ==="

stop_service() {
    local name=$1
    local pid_file="$PID_DIR/$name.pid"

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Parando $name (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            echo "✅ $name parado"
        else
            echo "⚠️  Processo $name (PID: $pid) não existe mais"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  PID file não encontrado para $name"
    fi
}

stop_service "hotwire"
stop_service "api"
stop_service "vue"

echo ""
echo "✅ Todos os serviços foram parados"

