# Danish Energy Analytics Platform: Deployment Guide

**Author:** Manus AI  
**Date:** June 15, 2025  
**Version:** 1.0  
**Target Audience:** DevOps Engineers, System Administrators, Technical Teams

---

## Table of Contents

1. [Prerequisites and System Requirements](#prerequisites-and-system-requirements)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Database Configuration](#database-configuration)
4. [Application Deployment](#application-deployment)
5. [Configuration Management](#configuration-management)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Security Configuration](#security-configuration)
8. [Troubleshooting Guide](#troubleshooting-guide)

---

## Prerequisites and System Requirements

### Hardware Requirements

The Danish Energy Analytics Platform is designed to run efficiently on modern server infrastructure with the following minimum and recommended specifications:

**Minimum Requirements:**
- CPU: 4 cores (Intel Xeon or AMD EPYC equivalent)
- RAM: 16 GB
- Storage: 500 GB SSD
- Network: 1 Gbps connection

**Recommended Production Requirements:**
- CPU: 8+ cores (Intel Xeon or AMD EPYC equivalent)
- RAM: 32+ GB
- Storage: 1+ TB NVMe SSD
- Network: 10 Gbps connection
- Backup Storage: 2+ TB for data retention

**Cloud Infrastructure (Azure Recommended):**
- Virtual Machine: Standard_D8s_v3 or higher
- Database: Azure Database for PostgreSQL (General Purpose, 4 vCores)
- Storage: Premium SSD with 1000+ IOPS
- Networking: Virtual Network with appropriate security groups

### Software Dependencies

**Operating System:**
- Ubuntu 22.04 LTS (recommended)
- CentOS 8+ or RHEL 8+
- Windows Server 2019+ (with WSL2 for development)

**Core Runtime Dependencies:**
```bash
# Python 3.11+
python3.11
python3.11-pip
python3.11-venv

# PostgreSQL 14+
postgresql-14
postgresql-client-14
postgresql-contrib-14

# Node.js 18+ (for dashboard)
nodejs
npm

# System utilities
git
curl
wget
unzip
```

**Python Package Dependencies:**
```bash
# Core data processing
pandas>=1.5.0
numpy>=1.24.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0

# Data transformation
dbt-core>=1.6.0
dbt-postgres>=1.6.0

# Machine learning
scikit-learn>=1.3.0
xgboost>=1.7.0
lightgbm>=4.0.0
tensorflow>=2.13.0

# Web framework
flask>=2.3.0
flask-cors>=4.0.0

# Utilities
requests>=2.31.0
python-dotenv>=1.0.0
schedule>=1.2.0
```

### Network and Security Requirements

**Firewall Configuration:**
- Port 5432: PostgreSQL database access
- Port 5000: API server (internal)
- Port 3000: Dashboard application
- Port 443: HTTPS access (production)
- Port 22: SSH access (administrative)

**External API Access:**
- Energinet API: https://api.energidataservice.dk
- Danish Energy Agency: https://ens.dk
- Nord Pool: https://www.nordpoolgroup.com

**SSL/TLS Requirements:**
- Valid SSL certificates for production deployment
- TLS 1.3 support for all external communications
- Certificate management and renewal procedures

---

## Infrastructure Setup

### Local Development Environment

For development and testing purposes, the platform can be deployed on a local machine or development server:

```bash
# 1. Clone the repository
git clone <repository-url>
cd danish_energy_project

# 2. Create Python virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install Python dependencies
pip install -r requirements.txt

# 4. Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# 5. Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs

# 6. Verify installations
python --version  # Should be 3.11+
psql --version    # Should be 14+
node --version    # Should be 18+
npm --version     # Should be 9+
```

### Azure Cloud Deployment

For production deployment on Azure, follow these steps to set up the required infrastructure:

```bash
# 1. Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Login to Azure
az login

# 3. Create resource group
az group create --name danish-energy-rg --location westeurope

# 4. Create virtual network
az network vnet create \
  --resource-group danish-energy-rg \
  --name danish-energy-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.1.0/24

# 5. Create virtual machine
az vm create \
  --resource-group danish-energy-rg \
  --name danish-energy-vm \
  --image Ubuntu2204 \
  --size Standard_D8s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name danish-energy-vnet \
  --subnet default

# 6. Create PostgreSQL database
az postgres server create \
  --resource-group danish-energy-rg \
  --name danish-energy-db \
  --location westeurope \
  --admin-user dbadmin \
  --admin-password <secure-password> \
  --sku-name GP_Gen5_4 \
  --version 14

# 7. Configure firewall rules
az postgres server firewall-rule create \
  --resource-group danish-energy-rg \
  --server danish-energy-db \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Container Deployment (Docker)

For containerized deployment, use the provided Docker configuration:

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose ports
EXPOSE 5000

# Start application
CMD ["python", "app.py"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  database:
    image: postgres:14
    environment:
      POSTGRES_DB: danish_energy_analytics
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  api:
    build: .
    environment:
      DATABASE_URL: postgresql://postgres:postgres@database:5432/danish_energy_analytics
    depends_on:
      - database
    ports:
      - "5000:5000"

  dashboard:
    build: ./dashboards/energy-dashboard
    ports:
      - "3000:3000"
    depends_on:
      - api

volumes:
  postgres_data:
```

---

## Database Configuration

### PostgreSQL Installation and Setup

```bash
# 1. Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# 2. Start and enable PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 3. Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE danish_energy_analytics;
CREATE USER analytics_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE danish_energy_analytics TO analytics_user;
\q
EOF

# 4. Configure PostgreSQL for optimal performance
sudo nano /etc/postgresql/14/main/postgresql.conf
```

**PostgreSQL Configuration Optimizations:**

```ini
# Memory settings
shared_buffers = 8GB                    # 25% of total RAM
effective_cache_size = 24GB             # 75% of total RAM
work_mem = 256MB                        # For complex queries
maintenance_work_mem = 2GB              # For maintenance operations

# Connection settings
max_connections = 200                   # Adjust based on load
shared_preload_libraries = 'pg_stat_statements'

# Performance settings
random_page_cost = 1.1                  # For SSD storage
effective_io_concurrency = 200          # For SSD storage
max_worker_processes = 8                # Number of CPU cores
max_parallel_workers_per_gather = 4     # Parallel query workers

# Logging settings
log_statement = 'mod'                   # Log modifications
log_min_duration_statement = 1000       # Log slow queries (1 second)
log_checkpoints = on
log_connections = on
log_disconnections = on
```

### Database Schema Deployment

```bash
# 1. Navigate to data warehouse directory
cd data_warehouse

# 2. Execute schema creation scripts in order
psql -h localhost -U analytics_user -d danish_energy_analytics -f 01_create_schemas.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 02_create_raw_tables.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 03_create_dimension_tables.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 04_create_fact_tables.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 05_create_analytics_tables.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 06_create_data_loading_functions.sql
psql -h localhost -U analytics_user -d danish_energy_analytics -f 07_create_etl_procedures.sql

# 3. Verify schema creation
psql -h localhost -U analytics_user -d danish_energy_analytics -c "\dt raw.*"
psql -h localhost -U analytics_user -d danish_energy_analytics -c "\dt core.*"
psql -h localhost -U analytics_user -d danish_energy_analytics -c "\dt analytics.*"
```

### Initial Data Loading

```bash
# 1. Run data extraction
cd data_ingestion
python extract_energy_data.py

# 2. Load data into warehouse
cd ../data_warehouse
python load_data_warehouse.py

# 3. Verify data loading
psql -h localhost -U analytics_user -d danish_energy_analytics -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as rows_inserted,
    n_tup_upd as rows_updated
FROM pg_stat_user_tables 
WHERE schemaname IN ('raw', 'core', 'analytics')
ORDER BY schemaname, tablename;
"
```

---

## Application Deployment

### API Server Deployment

```bash
# 1. Navigate to dashboard directory
cd dashboards

# 2. Create environment configuration
cat > .env << EOF
DATABASE_URL=postgresql://analytics_user:secure_password@localhost:5432/danish_energy_analytics
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your-secret-key-here
CORS_ORIGINS=https://your-domain.com
EOF

# 3. Install Python dependencies
pip install -r requirements.txt

# 4. Test API server
python dashboard_api.py

# 5. Create systemd service for production
sudo nano /etc/systemd/system/danish-energy-api.service
```

**Systemd Service Configuration:**

```ini
[Unit]
Description=Danish Energy Analytics API
After=network.target postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/danish_energy_project/dashboards
Environment=PATH=/home/ubuntu/danish_energy_project/venv/bin
ExecStart=/home/ubuntu/danish_energy_project/venv/bin/python dashboard_api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable danish-energy-api
sudo systemctl start danish-energy-api
sudo systemctl status danish-energy-api
```

### Dashboard Deployment

```bash
# 1. Navigate to dashboard directory
cd dashboards/energy-dashboard

# 2. Install Node.js dependencies
npm install

# 3. Build production version
npm run build

# 4. Install serve for production hosting
npm install -g serve

# 5. Start production server
serve -s dist -l 3000

# 6. Create systemd service for dashboard
sudo nano /etc/systemd/system/danish-energy-dashboard.service
```

**Dashboard Service Configuration:**

```ini
[Unit]
Description=Danish Energy Analytics Dashboard
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/danish_energy_project/dashboards/energy-dashboard
ExecStart=/usr/bin/serve -s dist -l 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Machine Learning Model Deployment

```bash
# 1. Navigate to ML models directory
cd ml_models

# 2. Train and save models
python simplified_ml_pipeline.py
python advanced_ml_pipeline.py

# 3. Create model serving API
cat > model_api.py << 'EOF'
from flask import Flask, request, jsonify
import joblib
import pandas as pd
import numpy as np
from datetime import datetime

app = Flask(__name__)

# Load trained models
models = {
    'co2_emission': joblib.load('models/co2_emission_model.joblib'),
    'renewable_energy': joblib.load('models/renewable_energy_model.joblib'),
    'electricity_price': joblib.load('models/electricity_price_model.joblib')
}

scalers = {
    'co2_emission': joblib.load('models/co2_emission_scaler.joblib'),
    'renewable_energy': joblib.load('models/renewable_energy_scaler.joblib'),
    'electricity_price': joblib.load('models/electricity_price_scaler.joblib')
}

@app.route('/predict/<model_name>', methods=['POST'])
def predict(model_name):
    if model_name not in models:
        return jsonify({'error': 'Model not found'}), 404
    
    try:
        data = request.json
        features = pd.DataFrame([data])
        
        # Scale features
        features_scaled = scalers[model_name].transform(features)
        
        # Make prediction
        prediction = models[model_name].predict(features_scaled)[0]
        
        return jsonify({
            'model': model_name,
            'prediction': float(prediction),
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

# 4. Test model API
python model_api.py
```

---

## Configuration Management

### Environment Variables

Create a comprehensive environment configuration file:

```bash
# Create .env file
cat > .env << EOF
# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=danish_energy_analytics
DATABASE_USER=analytics_user
DATABASE_PASSWORD=secure_password
DATABASE_URL=postgresql://analytics_user:secure_password@localhost:5432/danish_energy_analytics

# API Configuration
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your-very-secure-secret-key-here
API_HOST=0.0.0.0
API_PORT=5000

# External API Keys
ENERGINET_API_KEY=your-energinet-api-key
NORDPOOL_API_KEY=your-nordpool-api-key

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=/var/log/danish-energy/app.log

# Security Configuration
CORS_ORIGINS=https://your-domain.com,https://dashboard.your-domain.com
JWT_SECRET_KEY=your-jwt-secret-key
SESSION_TIMEOUT=3600

# Performance Configuration
CACHE_TIMEOUT=300
MAX_WORKERS=4
BATCH_SIZE=1000

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
EOF
```

### Application Configuration

```python
# config.py
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Database
    DATABASE_URL = os.getenv('DATABASE_URL')
    
    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    
    # API
    API_HOST = os.getenv('API_HOST', '127.0.0.1')
    API_PORT = int(os.getenv('API_PORT', 5000))
    
    # External APIs
    ENERGINET_API_KEY = os.getenv('ENERGINET_API_KEY')
    NORDPOOL_API_KEY = os.getenv('NORDPOOL_API_KEY')
    
    # Security
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')
    
    # Performance
    CACHE_TIMEOUT = int(os.getenv('CACHE_TIMEOUT', 300))
    MAX_WORKERS = int(os.getenv('MAX_WORKERS', 4))
    
class DevelopmentConfig(Config):
    DEBUG = True
    FLASK_ENV = 'development'

class ProductionConfig(Config):
    DEBUG = False
    FLASK_ENV = 'production'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
```

### Logging Configuration

```python
# logging_config.py
import logging
import logging.handlers
import os

def setup_logging():
    log_level = os.getenv('LOG_LEVEL', 'INFO')
    log_file = os.getenv('LOG_FILE', '/var/log/danish-energy/app.log')
    
    # Create log directory if it doesn't exist
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    
    # Configure logging
    logging.basicConfig(
        level=getattr(logging, log_level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.handlers.RotatingFileHandler(
                log_file, maxBytes=10485760, backupCount=5
            ),
            logging.StreamHandler()
        ]
    )
    
    return logging.getLogger(__name__)
```

---

## Monitoring and Logging

### Application Monitoring

```bash
# 1. Install monitoring tools
pip install prometheus-client psutil

# 2. Create monitoring endpoint
cat > monitoring.py << 'EOF'
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from flask import Response
import psutil
import time

# Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
ACTIVE_CONNECTIONS = Gauge('database_connections_active', 'Active database connections')
CPU_USAGE = Gauge('system_cpu_usage_percent', 'System CPU usage')
MEMORY_USAGE = Gauge('system_memory_usage_percent', 'System memory usage')

def update_system_metrics():
    CPU_USAGE.set(psutil.cpu_percent())
    MEMORY_USAGE.set(psutil.virtual_memory().percent)

@app.route('/metrics')
def metrics():
    update_system_metrics()
    return Response(generate_latest(), mimetype='text/plain')
EOF

# 3. Install and configure Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# 4. Create Prometheus configuration
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'danish-energy-api'
    static_configs:
      - targets: ['localhost:5000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'postgresql'
    static_configs:
      - targets: ['localhost:9187']
EOF

# 5. Start Prometheus
./prometheus --config.file=prometheus.yml
```

### Log Management

```bash
# 1. Configure log rotation
sudo nano /etc/logrotate.d/danish-energy

# Add the following content:
/var/log/danish-energy/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload danish-energy-api
    endscript
}

# 2. Create log analysis script
cat > log_analysis.py << 'EOF'
import re
import json
from collections import defaultdict
from datetime import datetime

def analyze_logs(log_file):
    error_counts = defaultdict(int)
    response_times = []
    
    with open(log_file, 'r') as f:
        for line in f:
            # Parse error messages
            if 'ERROR' in line:
                error_counts['errors'] += 1
            
            # Parse response times
            time_match = re.search(r'response_time: (\d+\.?\d*)', line)
            if time_match:
                response_times.append(float(time_match.group(1)))
    
    # Calculate statistics
    if response_times:
        avg_response_time = sum(response_times) / len(response_times)
        max_response_time = max(response_times)
    else:
        avg_response_time = max_response_time = 0
    
    return {
        'error_count': error_counts['errors'],
        'avg_response_time': avg_response_time,
        'max_response_time': max_response_time,
        'total_requests': len(response_times)
    }

if __name__ == '__main__':
    stats = analyze_logs('/var/log/danish-energy/app.log')
    print(json.dumps(stats, indent=2))
EOF
```

### Health Checks

```python
# health_check.py
import requests
import psycopg2
import sys
import json
from datetime import datetime

def check_database():
    try:
        conn = psycopg2.connect(
            host='localhost',
            database='danish_energy_analytics',
            user='analytics_user',
            password='secure_password'
        )
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        conn.close()
        return True, "Database connection successful"
    except Exception as e:
        return False, f"Database connection failed: {str(e)}"

def check_api():
    try:
        response = requests.get('http://localhost:5000/api/health', timeout=5)
        if response.status_code == 200:
            return True, "API server responding"
        else:
            return False, f"API server returned status {response.status_code}"
    except Exception as e:
        return False, f"API server check failed: {str(e)}"

def check_dashboard():
    try:
        response = requests.get('http://localhost:3000', timeout=5)
        if response.status_code == 200:
            return True, "Dashboard responding"
        else:
            return False, f"Dashboard returned status {response.status_code}"
    except Exception as e:
        return False, f"Dashboard check failed: {str(e)}"

def main():
    checks = [
        ('Database', check_database),
        ('API', check_api),
        ('Dashboard', check_dashboard)
    ]
    
    results = {}
    all_healthy = True
    
    for name, check_func in checks:
        healthy, message = check_func()
        results[name] = {
            'healthy': healthy,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        if not healthy:
            all_healthy = False
    
    results['overall_health'] = all_healthy
    
    print(json.dumps(results, indent=2))
    
    if not all_healthy:
        sys.exit(1)

if __name__ == '__main__':
    main()
```

This deployment guide provides comprehensive instructions for setting up the Danish Energy Analytics Platform in various environments, from local development to production cloud deployment. The guide includes detailed configuration management, monitoring setup, and troubleshooting procedures to ensure reliable operation.

