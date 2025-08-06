-- ============================================================================
-- Bulk Data Generation for Performance Testing
-- Execute this in sensor_data database after sample data
-- ============================================================================

-- Generate bulk data for hot table (recent data - last 7 days)
INSERT INTO sensors.temperature_hot (time, sensor_id, temperature, location, device_type)
SELECT
    NOW() - (random() * INTERVAL '7 days'),
    'sensor_' || lpad((random() * 50)::int::text, 3, '0'),
    18 + (random() * 15), -- Temperature between 18-33°C
    'warehouse_' || chr(65 + (random() * 10)::int), -- Warehouse A-K
    CASE WHEN random() < 0.7 THEN 'temp_sensor' ELSE 'humidity_sensor' END
FROM generate_series(1, 5000); -- 5,000 records

-- Generate bulk data for cold table (8-90 days old)
INSERT INTO sensors.temperature_cold (time, sensor_id, temperature, location, device_type)
SELECT
    NOW() - INTERVAL '8 days' - (random() * INTERVAL '82 days'), -- 8-90 days ago
    'sensor_' || lpad((random() * 50)::int::text, 3, '0'),
    18 + (random() * 15),
    'warehouse_' || chr(65 + (random() * 10)::int),
    CASE WHEN random() < 0.7 THEN 'temp_sensor' ELSE 'humidity_sensor' END
FROM generate_series(1, 10000); -- 10,000 records

-- Generate bulk data for archive table (older than 90 days)
INSERT INTO sensors.temperature_archive (time, sensor_id, temperature, location, device_type)
SELECT
    NOW() - INTERVAL '91 days' - (random() * INTERVAL '730 days'), -- 91 days to 2+ years ago
    'sensor_' || lpad((random() * 50)::int::text, 3, '0'),
    18 + (random() * 15),
    'warehouse_' || chr(65 + (random() * 10)::int),
    CASE WHEN random() < 0.7 THEN 'temp_sensor' ELSE 'humidity_sensor' END
FROM generate_series(1, 15000); -- 15,000 records

-- Show data distribution summary
SELECT
    'hot_data (< 7 days)' as data_tier,
    COUNT(*) as record_count,
    MIN(time) as oldest_record,
    MAX(time) as newest_record,
    pg_size_pretty(pg_total_relation_size('sensors.temperature_hot')) as table_size
FROM sensors.temperature_hot
UNION ALL
SELECT
    'cold_data (8-90 days)',
    COUNT(*),
    MIN(time),
    MAX(time),
    pg_size_pretty(pg_total_relation_size('sensors.temperature_cold'))
FROM sensors.temperature_cold
UNION ALL
SELECT
    'archive_data (> 90 days)',
    COUNT(*),
    MIN(time),
    MAX(time),
    pg_size_pretty(pg_total_relation_size('sensors.temperature_archive'))
FROM sensors.temperature_archive;
