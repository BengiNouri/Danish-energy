#!/bin/bash

# Danish Energy Analytics Platform - Stop Services Script
# Stops running platform services using stored PID files

set -e

echo "🛑 Stopping Danish Energy Analytics Platform services"

# Ensure we're in the project root
if [ ! -f "data_ingestion/extract_energy_data.py" ]; then
    echo "❌ Please run this script from the danish_energy_project directory"
    exit 1
fi

stop_service() {
    local pid_file="$1"
    local name="$2"

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        kill "$pid" 2>/dev/null || true
        rm "$pid_file"
        echo "✅ $name stopped"
    else
        echo "ℹ️ $name not running"
    fi
}

stop_service api.pid "API server"
stop_service dashboard.pid "Dashboard"
stop_service ml.pid "ML server"

echo "🚦 All services stopped"
