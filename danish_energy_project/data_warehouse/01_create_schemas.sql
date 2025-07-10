-- Danish Energy Analytics Data Warehouse Schema
-- PostgreSQL implementation of the star schema design
-- Author: Manus AI
-- Date: 2025-06-15

-- Create schemas for organizing the data warehouse
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS raw;

-- Grant permissions on schemas
GRANT USAGE ON SCHEMA staging TO analytics_user;
GRANT USAGE ON SCHEMA core TO analytics_user;
GRANT USAGE ON SCHEMA analytics TO analytics_user;
GRANT USAGE ON SCHEMA raw TO analytics_user;

GRANT CREATE ON SCHEMA staging TO analytics_user;
GRANT CREATE ON SCHEMA core TO analytics_user;
GRANT CREATE ON SCHEMA analytics TO analytics_user;
GRANT CREATE ON SCHEMA raw TO analytics_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT ALL ON TABLES TO analytics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON TABLES TO analytics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT ALL ON TABLES TO analytics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT ALL ON TABLES TO analytics_user;

-- Create extensions for enhanced functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Comment on database
COMMENT ON DATABASE danish_energy_analytics IS 'Data warehouse for Danish energy consumption, production, and emissions analytics';

-- Comment on schemas
COMMENT ON SCHEMA raw IS 'Raw data from external sources';
COMMENT ON SCHEMA staging IS 'Cleaned and standardized data';
COMMENT ON SCHEMA core IS 'Dimensional model - fact and dimension tables';
COMMENT ON SCHEMA analytics IS 'Analytics-ready data marts and aggregations';

