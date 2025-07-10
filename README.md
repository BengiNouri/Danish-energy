# Danish Energy Analytics Platform

This repository contains the code for the Danish Energy Analytics Platform. It provides data ingestion, transformation, a PostgreSQL data warehouse and interactive dashboards.

## Running the Platform on Ubuntu or in Visual Studio Code

1. **Clone the repository**
   ```bash
   git clone <this repo>
   cd Danish-energy
   ```

2. **Install prerequisites** (Ubuntu 22.04 or WSL recommended). The easiest approach is to use the provided `quick_setup.sh` script which installs Python, PostgreSQL, Node.js and all Python dependencies:
   ```bash
   cd danish_energy_project
   ./quick_setup.sh
   ```
   This script creates a Python virtual environment in `venv/`, installs packages from `requirements.txt`, sets up PostgreSQL and loads sample data.

3. **Start the services**
   ```bash
   ./start_services.sh
   ```
   The API will be available at `http://localhost:5000` and the dashboard at `http://localhost:5173`.

4. **Stop the services**
   ```bash
   ./stop_services.sh
   ```

5. **Run tests**
   ```bash
   make test
   ```

These steps can also be triggered with `make up` from the repository root, which runs the setup and starts the services in one command.
