#!/bin/bash

# Danish Energy Analytics Platform - Service Starter
# This script starts all platform services for local development

set -e

echo "🚀 Starting Danish Energy Analytics Platform Services"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "data_ingestion/extract_energy_data.py" ]; then
    echo "❌ Please run this script from the danish_energy_project directory"
    exit 1
fi

# Function to check if port is available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️ Port $1 is already in use"
        return 1
    fi
    return 0
}

# Function to start API server
start_api() {
    echo "🔌 Starting API server on port 5000..."
    
    if ! check_port 5000; then
        echo "❌ Cannot start API server - port 5000 is busy"
        return 1
    fi
    
    cd dashboards
    source ../venv/bin/activate
    python dashboard_api.py &
    API_PID=$!
    echo $API_PID > ../api.pid
    cd ..
    
    # Wait for API to start
    sleep 3
    if curl -s http://localhost:5000/api/health > /dev/null; then
        echo "✅ API server started successfully"
    else
        echo "❌ API server failed to start"
        return 1
    fi
}

# Function to start dashboard
start_dashboard() {
    echo "📊 Starting dashboard on port 4173..."
    
    if ! check_port 4173; then
        echo "⚠️ Port 4173 is busy, trying port 3000..."
        if ! check_port 3000; then
            echo "❌ Cannot start dashboard - both ports are busy"
            return 1
        fi
        DASHBOARD_PORT=3000
    else
        DASHBOARD_PORT=4173
    fi
    
    cd dashboards/energy-dashboard
    npm run preview -- --port $DASHBOARD_PORT &
    DASHBOARD_PID=$!
    echo $DASHBOARD_PID > ../../dashboard.pid
    cd ../..
    
    # Wait for dashboard to start
    sleep 5
    if curl -s http://localhost:$DASHBOARD_PORT > /dev/null; then
        echo "✅ Dashboard started successfully"
        DASHBOARD_URL="http://localhost:$DASHBOARD_PORT"
    else
        echo "❌ Dashboard failed to start"
        return 1
    fi
}

# Function to start ML model server
start_ml_server() {
    echo "🤖 Starting ML model server on port 5001..."
    
    if ! check_port 5001; then
        echo "⚠️ Port 5001 is busy, skipping ML server"
        return 0
    fi
    
    cd ml_models
    if [ -f "model_api.py" ]; then
        source ../venv/bin/activate
        python model_api.py &
        ML_PID=$!
        echo $ML_PID > ../ml.pid
        echo "✅ ML model server started"
    else
        echo "⚠️ ML model server not available"
    fi
    cd ..
}

# Function to display service status
show_status() {
    echo ""
    echo "🎉 Danish Energy Analytics Platform is running!"
    echo "=============================================="
    echo ""
    echo "📊 Dashboard:     $DASHBOARD_URL"
    echo "🔌 API Server:    http://localhost:5000"
    echo "📚 API Docs:      http://localhost:5000/docs"
    
    if [ -f "ml.pid" ]; then
        echo "🤖 ML Server:     http://localhost:5001"
    fi
    
    echo ""
    echo "📋 Service Management:"
    echo "  Stop services:  ./stop_services.sh"
    echo "  View logs:      tail -f *.log"
    echo "  Health check:   curl http://localhost:5000/api/health"
    echo ""
    echo "📚 Documentation:"
    echo "  User Guide:     docs/user_guides/user_guide.md"
    echo "  API Docs:       http://localhost:5000/docs"
    echo "  Tech Docs:      docs/technical_docs/"
    echo ""
    echo "Press Ctrl+C to stop all services"
}

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    
    if [ -f "api.pid" ]; then
        kill $(cat api.pid) 2>/dev/null || true
        rm api.pid
    fi
    
    if [ -f "dashboard.pid" ]; then
        kill $(cat dashboard.pid) 2>/dev/null || true
        rm dashboard.pid
    fi
    
    if [ -f "ml.pid" ]; then
        kill $(cat ml.pid) 2>/dev/null || true
        rm ml.pid
    fi
    
    echo "✅ All services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
main() {
    # Check prerequisites
    if [ ! -d "venv" ]; then
        echo "❌ Python virtual environment not found. Run ./quick_setup.sh first."
        exit 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        echo "❌ npm not found. Please install Node.js and npm."
        exit 1
    fi
    
    # Start services
    start_api
    start_dashboard
    start_ml_server
    
    # Show status and wait
    show_status
    
    # Keep script running
    while true; do
        sleep 1
    done
}

# Run main function
main "$@"

