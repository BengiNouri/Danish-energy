#!/usr/bin/env bash

# Danish Energy Analytics Platform - Quick Setup Script
# Automated local dev setup on WSL/Ubuntu

set -e  # Exit on any error

# Default location for raw CSVs
DATA_PATH_DEFAULT="$(pwd)/data_ingestion/raw_data"
export DANISH_ENERGY_DATA_PATH="${DANISH_ENERGY_DATA_PATH:-$DATA_PATH_DEFAULT}"
echo "Using data path: $DANISH_ENERGY_DATA_PATH"

echo "🚀 Danish Energy Analytics Platform - Quick Setup"
echo "================================================="

# Prevent running as root
if [ "$EUID" -eq 0 ]; then
  echo "❌ Please do NOT run this as root"
  exit 1
fi

# Check command existence
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_system_deps() {
  echo "📦 Installing system dependencies…"

  if command_exists apt-get; then
    sudo apt-get update
    # Core packages pinned to stable versions
    sudo apt-get install -y \
      python3.11 python3.11-venv python3.11-pip \
      postgresql=16+257build1.1 postgresql-contrib=16+257build1.1 \
      build-essential libpq-dev curl git
    # Node.js pinned version
    sudo apt-get install -y nodejs=18.19.1+dfsg-6ubuntu5
    # Install pnpm globally
    sudo npm install -g pnpm@10.4.1
  else
    echo "⚠️ Unsupported package manager detected."
    echo "   Please install Python 3.11, PostgreSQL 16, Node.js 18.19.1 and pnpm 10.4.1 using your system's package manager."
    return 1
  fi
}

setup_python_env() {
  echo "🐍 Setting up Python venv & packages…"

  if [ ! -d "venv" ]; then
    python3.11 -m venv venv
  fi

  source venv/bin/activate
  pip install --upgrade pip
  # Install pinned project requirements
  pip install -r requirements.txt

  echo "✅ Python environment ready"
}

setup_database() {
  echo "🗄️ Setting up PostgreSQL database…"

  # Ensure service is running
  sudo systemctl start postgresql
  sudo systemctl enable postgresql

  # Create DB + user
  sudo -u postgres psql <<EOF
CREATE DATABASE danish_energy_analytics;
CREATE USER analytics_user WITH PASSWORD 'analytics_password';
GRANT ALL PRIVILEGES ON DATABASE danish_energy_analytics TO analytics_user;
EOF

  # Apply schema migrations
  cd data_warehouse
  for f in {01..07}_*.sql; do
    PGPASSWORD=analytics_password psql -h localhost -U analytics_user -d danish_energy_analytics -f "$f"
  done
  cd ..

  echo "✅ Database schema applied"
}

extract_sample_data() {
  echo "📊 Extracting sample data…"
  cd data_ingestion
  source ../venv/bin/activate
  python extract_energy_data.py
  cd ..
  echo "✅ Raw CSVs pulled"
}

load_data_warehouse() {
  echo "🏗️ Loading & transforming data…"
  cd data_warehouse
  source ../venv/bin/activate
  python load_data_warehouse.py
  cd ..
  echo "✅ Data warehouse populated"
}

setup_dashboard() {
  echo "📊 Installing & building React dashboard (dev mode)…"
  cd dashboards/energy-dashboard
  pnpm install
  pnpm run dev &
  DASHBOARD_PID=$!
  cd ../..
  echo "✅ Dashboard running at http://localhost:5173 (PID $DASHBOARD_PID)"
}

run_health_checks() {
  echo "🔍 Running health checks…"

  # DB connectivity
  PGPASSWORD=analytics_password psql -h localhost -U analytics_user -d danish_energy_analytics -c "SELECT 1;" >/dev/null
  echo "✅ PostgreSQL connection OK"

  # Python packages
  source venv/bin/activate
  python - <<PYCODE
import flask, flask_cors, pandas, psycopg2, requests
print("✅ Python packages OK")
PYCODE

  # Sample data count
  record_count=$(PGPASSWORD=analytics_password psql -h localhost -U analytics_user -d danish_energy_analytics -t -c "SELECT COUNT(*) FROM raw.co2_emissions;")
  if [ "$record_count" -gt 0 ]; then
    echo "✅ Data loaded: $record_count records in raw.co2_emissions"
  else
    echo "⚠️ No records found in raw.co2_emissions"
  fi
}

start_api() {
  echo "🚀 Starting Flask API…"
  cd dashboards
  source ../venv/bin/activate
  nohup python dashboard_api.py > api.log 2>&1 &
  API_PID=$!
  cd ..
  echo "✅ API running at http://localhost:5000 (PID $API_PID)"
}

main() {
  echo ""
  if [ ! -f "data_ingestion/extract_energy_data.py" ]; then
    echo "❌ Run this from the Danish energy project root"
    exit 1
  fi

  install_system_deps
  setup_python_env
  setup_database
  extract_sample_data
  load_data_warehouse
  start_api
  setup_dashboard
  run_health_checks

  echo ""
  echo "🎉 All set! Access your platform at:"
  echo "   • Dashboard: http://localhost:5173"
  echo "   • API:       http://localhost:5000"
  echo ""
  echo "To stop everything: kill $API_PID $DASHBOARD_PID"
}

main "$@"
