# Required Environment Variables

The Danish Energy Analytics Platform relies on the following variables. Create a `.env` file at the project root and populate these values before starting the services.

| Variable | Description |
|----------|-------------|
| `DATABASE_HOST` | Database server hostname |
| `DATABASE_PORT` | Database port (default `5432`) |
| `DATABASE_NAME` | PostgreSQL database name |
| `DATABASE_USER` | PostgreSQL user |
| `DATABASE_PASSWORD` | PostgreSQL password |
| `DATABASE_URL` | Full database connection string |
| `FLASK_ENV` | Flask environment (`development` or `production`) |
| `FLASK_DEBUG` | Enable debug mode (usually `False` in production) |
| `SECRET_KEY` | Secret key for session security |
| `API_HOST` | Host interface for the API server |
| `API_PORT` | Port for the API server |
| `ENERGINET_API_KEY` | API key for Energinet data |
| `NORDPOOL_API_KEY` | API key for Nord Pool data |
| `LOG_LEVEL` | Logging level (e.g. `INFO`) |
| `LOG_FILE` | Log file path |
| `CORS_ORIGINS` | Allowed CORS origins (comma‑separated) |
| `JWT_SECRET_KEY` | Secret used for JWT tokens |
| `SESSION_TIMEOUT` | User session timeout in seconds |
| `CACHE_TIMEOUT` | Cache expiry time in seconds |
| `MAX_WORKERS` | Number of worker processes |
| `BATCH_SIZE` | Batch size for background jobs |
| `PROMETHEUS_PORT` | Prometheus metrics port |
| `GRAFANA_PORT` | Grafana dashboard port |
