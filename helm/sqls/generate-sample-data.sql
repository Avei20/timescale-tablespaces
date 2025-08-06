-- ============================================================================
-- Sample Data Generation for Tablespace PoC
-- Execute this in sensor_data database
-- ============================================================================

-- Insert sample recent data into hot table (last 7 days)
INSERT INTO sensors.temperature_hot (time, sensor_id, temperature, location, device_type)
VALUES
    (NOW() - INTERVAL '1 hour', 'sensor_001', 25.5, 'warehouse_a', 'temp_sensor'),
    (NOW() - INTERVAL '2 hours', 'sensor_002', 24.8, 'warehouse_b', 'temp_sensor'),
    (NOW() - INTERVAL '4 hours', 'sensor_003', 26.2, 'warehouse_c', 'temp_sensor'),
    (NOW() - INTERVAL '6 hours', 'sensor_001', 25.1, 'warehouse_a', 'temp_sensor'),
    (NOW() - INTERVAL '12 hours', 'sensor_004', 23.9, 'warehouse_d', 'temp_sensor'),
    (NOW() - INTERVAL '1 day', 'sensor_002', 24.4, 'warehouse_b', 'temp_sensor'),
    (NOW() - INTERVAL '2 days', 'sensor_005', 27.1, 'warehouse_e', 'temp_sensor'),
    (NOW() - INTERVAL '3 days', 'sensor_003', 25.8, 'warehouse_c', 'temp_sensor'),
    (NOW() - INTERVAL '5 days', 'sensor_006', 22.7, 'warehouse_f', 'temp_sensor'),
    (NOW() - INTERVAL '6 days', 'sensor_001', 26.3, 'warehouse_a', 'temp_sensor');

-- Insert historical data into cold table (8-90 days old)
INSERT INTO sensors.temperature_cold (time, sensor_id, temperature, location, device_type)
VALUES
    (NOW() - INTERVAL '15 days', 'sensor_001', 23.1, 'warehouse_a', 'temp_sensor'),
    (NOW() - INTERVAL '20 days', 'sensor_002', 22.9, 'warehouse_b', 'temp_sensor'),
    (NOW() - INTERVAL '25 days', 'sensor_003', 24.7, 'warehouse_c', 'temp_sensor'),
    (NOW() - INTERVAL '30 days', 'sensor_004', 21.5, 'warehouse_d', 'temp_sensor'),
    (NOW() - INTERVAL '45 days', 'sensor_005', 26.8, 'warehouse_e', 'temp_sensor'),
    (NOW() - INTERVAL '60 days', 'sensor_006', 23.4, 'warehouse_f', 'temp_sensor'),
    (NOW() - INTERVAL '75 days', 'sensor_007', 25.2, 'warehouse_g', 'temp_sensor'),
    (NOW() - INTERVAL '80 days', 'sensor_008', 24.1, 'warehouse_h', 'temp_sensor');

-- Insert archive data (older than 90 days)
INSERT INTO sensors.temperature_archive (time, sensor_id, temperature, location, device_type)
VALUES
    (NOW() - INTERVAL '100 days', 'sensor_001', 21.5, 'warehouse_a', 'temp_sensor'),
    (NOW() - INTERVAL '150 days', 'sensor_002', 20.8, 'warehouse_b', 'temp_sensor'),
    (NOW() - INTERVAL '200 days', 'sensor_003', 22.1, 'warehouse_c', 'temp_sensor'),
    (NOW() - INTERVAL '250 days', 'sensor_004', 19.9, 'warehouse_d', 'temp_sensor'),
    (NOW() - INTERVAL '300 days', 'sensor_005', 24.3, 'warehouse_e', 'temp_sensor'),
    (NOW() - INTERVAL '365 days', 'sensor_006', 21.7, 'warehouse_f', 'temp_sensor');
