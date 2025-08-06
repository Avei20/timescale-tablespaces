-- ============================================================================
-- TimescaleDB Tablespace Setup Script
-- Execute this manually in DBeaver or your preferred PostgreSQL client
-- IMPORTANT: Fix permissions first using the steps above!
-- ============================================================================

-- Step 1: Verify directories are accessible (should not return errors)
\! ls -la /var/lib/postgresql/hot /var/lib/postgresql/cold /var/lib/postgresql/archive

-- Step 2: Create tablespaces
CREATE TABLESPACE hot_data LOCATION '/var/lib/postgresql/hot';
CREATE TABLESPACE cold_data LOCATION '/var/lib/postgresql/cold';
CREATE TABLESPACE archive_data LOCATION '/var/lib/postgresql/archive';

-- Step 3: Create database and schema
CREATE DATABASE sensor_data;

-- Step 4: Connect to sensor_data database (switch connection in DBeaver)
-- \c sensor_data; -- (This is for psql, in DBeaver just change database connection)

-- Step 5: Enable TimescaleDB extension (execute in sensor_data database)
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE SCHEMA sensors;

-- Step 6: Create tables with specific tablespaces
CREATE TABLE sensors.temperature_hot (
    time TIMESTAMPTZ NOT NULL,
    sensor_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    location TEXT,
    device_type TEXT
) TABLESPACE hot_data;

CREATE TABLE sensors.temperature_cold (
    time TIMESTAMPTZ NOT NULL,
    sensor_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    location TEXT,
    device_type TEXT
) TABLESPACE cold_data;

CREATE TABLE sensors.temperature_archive (
    time TIMESTAMPTZ NOT NULL,
    sensor_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    location TEXT,
    device_type TEXT
) TABLESPACE archive_data;

-- Step 7: Convert to hypertables
SELECT create_hypertable('sensors.temperature_hot', 'time');
SELECT create_hypertable('sensors.temperature_cold', 'time');
SELECT create_hypertable('sensors.temperature_archive', 'time');

-- Step 8: Create indexes on respective tablespaces
CREATE INDEX idx_hot_sensor_time ON sensors.temperature_hot (sensor_id, time DESC) TABLESPACE hot_data;
CREATE INDEX idx_cold_sensor_time ON sensors.temperature_cold (sensor_id, time DESC) TABLESPACE cold_data;
CREATE INDEX idx_archive_sensor_time ON sensors.temperature_archive (sensor_id, time DESC) TABLESPACE archive_data;

-- Step 9: Verification queries
SELECT spcname, pg_tablespace_location(oid) FROM pg_tablespace
WHERE spcname IN ('hot_data', 'cold_data', 'archive_data');

SELECT schemaname, tablename, tablespace FROM pg_tables
WHERE schemaname = 'sensors';
