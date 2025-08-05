#!/bin/bash
set -e

# Function to execute SQL with timestamp logging
execute_sql() {
    local db=$1
    local sql=$2
    echo "[$(date)] Executing SQL on $db: $sql"
    psql -v ON_ERROR_STOP=1 -U postgres -d "$db" -c "$sql"
    echo "[$(date)] SQL completed successfully"
}

echo "[$(date)] Starting manual database initialization"

# Check if TimescaleDB extension is available
if psql -U postgres -d postgres -c "SELECT 1 FROM pg_available_extensions WHERE name = 'timescaledb';" | grep -q 1; then
    echo "[$(date)] TimescaleDB extension is available"
else
    echo "[$(date)] ERROR: TimescaleDB extension is not available"
    exit 1
fi

# Create testdb if it doesn't exist
if ! psql -U postgres -lqt | cut -d \| -f 1 | grep -qw testdb; then
    echo "[$(date)] Creating testdb database"
    psql -U postgres -c "CREATE DATABASE testdb;"
else
    echo "[$(date)] Database testdb already exists"
fi

# Set up database
echo "[$(date)] Setting up testdb"

# Check and create tablespaces
execute_sql "testdb" "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tablespace WHERE spcname = 'fastspace') THEN
        CREATE TABLESPACE fastspace LOCATION '/mnt/fastpace';
        RAISE NOTICE 'Created fastspace tablespace';
    ELSE
        RAISE NOTICE 'fastspace tablespace already exists';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_tablespace WHERE spcname = 'slowspace') THEN
        CREATE TABLESPACE slowspace LOCATION '/mnt/slowpace';
        RAISE NOTICE 'Created slowspace tablespace';
    ELSE
        RAISE NOTICE 'slowspace tablespace already exists';
    END IF;
END
\$\$;"

# Create extension if not exists
execute_sql "testdb" "CREATE EXTENSION IF NOT EXISTS timescaledb;"

# Drop table if exists to ensure clean setup
execute_sql "testdb" "DROP TABLE IF EXISTS network_sensor CASCADE;"

# Create table
execute_sql "testdb" "
CREATE TABLE network_sensor (
  ts TIMESTAMPTZ NOT NULL,
  sensor_id INT NOT NULL,
  value DOUBLE PRECISION
);"

# Create hypertable
execute_sql "testdb" "SELECT create_hypertable('network_sensor', 'ts', chunk_time_interval => INTERVAL '1 day');"

# Attach tablespaces
execute_sql "testdb" "SELECT attach_tablespace('fastspace', 'network_sensor');"
execute_sql "testdb" "SELECT attach_tablespace('slowspace', 'network_sensor');"

# Insert sample data
execute_sql "testdb" "
INSERT INTO network_sensor (ts, sensor_id, value)
SELECT
  NOW() - INTERVAL '1 day' * g,
  (random()*10)::int,
  random()*100
FROM generate_series(0, 102) g;"

# Create migration procedure
execute_sql "testdb" "
CREATE OR REPLACE PROCEDURE move_old_chunks_to_cold(job_id int, config jsonb)
LANGUAGE plpgsql
AS \$\$
DECLARE
  ht REGCLASS;
  lag interval;
  destination_tablespace name;
  chunk REGCLASS;
BEGIN
  RAISE NOTICE 'Starting move_old_chunks_to_cold procedure execution';
  SELECT jsonb_object_field_text(config, 'hypertable')::regclass INTO STRICT ht;
  SELECT jsonb_object_field_text(config, 'lag')::interval INTO STRICT lag;
  SELECT jsonb_object_field_text(config, 'destination_tablespace') INTO STRICT destination_tablespace;

  IF ht IS NULL OR lag IS NULL OR destination_tablespace IS NULL THEN
    RAISE EXCEPTION 'Config must have hypertable, lag, and destination_tablespace';
  END IF;

  FOR chunk IN
    SELECT show_chunks(ht, older_than => lag)
  LOOP
    RAISE NOTICE 'Moving chunk: %', chunk::text;
    PERFORM move_chunk(
      chunk => chunk,
      destination_tablespace => destination_tablespace,
      index_destination_tablespace => destination_tablespace
    );
  END LOOP;
END
\$\$;"

# Add the job
execute_sql "testdb" "
DO \$\$
BEGIN
  -- Delete existing job if it exists to avoid duplicates
  DELETE FROM timescaledb_information.jobs WHERE proc_name = 'move_old_chunks_to_cold';

  -- Add the new job
  PERFORM add_job(
    'move_old_chunks_to_cold',
    '1d',
    config => '{\"hypertable\":\"network_sensor\",\"lag\":\"2 years\",\"destination_tablespace\":\"slowspace\"}'
  );
END
\$\$;"

# Verify data
execute_sql "testdb" "SELECT count(*) AS row_count FROM network_sensor;"

# Show tablespace setup
execute_sql "testdb" "SELECT * FROM pg_tablespace;"
execute_sql "testdb" "SELECT * FROM timescaledb_information.tablespaces;"
execute_sql "testdb" "SELECT * FROM timescaledb_information.chunks LIMIT 5;"

echo "[$(date)] Database initialization complete"
