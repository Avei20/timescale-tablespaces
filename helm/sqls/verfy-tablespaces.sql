-- ============================================================================
-- Tablespace Verification and Performance Testing
-- Execute this to verify tablespace setup and test performance
-- ============================================================================

-- 1. Verify tablespace locations
SELECT
    spcname as tablespace_name,
    pg_tablespace_location(oid) as physical_location,
    pg_size_pretty(pg_tablespace_size(spcname)) as size_used
FROM pg_tablespace
WHERE spcname IN ('hot_data', 'cold_data', 'archive_data')
ORDER BY pg_tablespace_size(spcname) DESC;

-- 2. Check table-to-tablespace mapping
SELECT
    schemaname,
    tablename,
    tablespace,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size
FROM pg_tables
WHERE schemaname = 'sensors'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 3. Check index locations
SELECT
    schemaname,
    tablename,
    indexname,
    tablespace as index_tablespace
FROM pg_indexes
WHERE schemaname = 'sensors' AND indexname LIKE 'idx_%';

-- 4. Data distribution verification
SELECT
    'hot_data' as storage_tier,
    COUNT(*) as record_count,
    MIN(time)::date as oldest_date,
    MAX(time)::date as newest_date,
    EXTRACT(days FROM (MAX(time) - MIN(time))) as days_span
FROM sensors.temperature_hot
UNION ALL
SELECT
    'cold_data',
    COUNT(*),
    MIN(time)::date,
    MAX(time)::date,
    EXTRACT(days FROM (MAX(time) - MIN(time)))
FROM sensors.temperature_cold
UNION ALL
SELECT
    'archive_data',
    COUNT(*),
    MIN(time)::date,
    MAX(time)::date,
    EXTRACT(days FROM (MAX(time) - MIN(time)))
FROM sensors.temperature_archive
ORDER BY newest_date DESC;

-- 5. Performance test queries
-- Query recent data (hot storage)
EXPLAIN (ANALYZE, BUFFERS)
SELECT sensor_id, COUNT(*), AVG(temperature), MAX(temperature)
FROM sensors.temperature_hot
WHERE time >= NOW() - INTERVAL '24 hours'
GROUP BY sensor_id
ORDER BY COUNT(*) DESC;

-- Query historical data (cold storage)
EXPLAIN (ANALYZE, BUFFERS)
SELECT location, COUNT(*), AVG(temperature)
FROM sensors.temperature_cold
WHERE time >= NOW() - INTERVAL '60 days' AND time < NOW() - INTERVAL '30 days'
GROUP BY location
ORDER BY AVG(temperature) DESC;

-- Query archive data
EXPLAIN (ANALYZE, BUFFERS)
SELECT device_type, COUNT(*), MIN(temperature), MAX(temperature)
FROM sensors.temperature_archive
WHERE time >= NOW() - INTERVAL '365 days' AND time < NOW() - INTERVAL '180 days'
GROUP BY device_type;

-- 6. Storage utilization by tablespace
SELECT
    ts.spcname,
    pg_size_pretty(pg_tablespace_size(ts.spcname)) as used_space,
    COUNT(t.tablename) as table_count,
    string_agg(t.tablename, ', ') as tables
FROM pg_tablespace ts
LEFT JOIN pg_tables t ON t.tablespace = ts.spcname
WHERE ts.spcname IN ('hot_data', 'cold_data', 'archive_data')
GROUP BY ts.spcname, ts.oid
ORDER BY pg_tablespace_size(ts.oid) DESC;
