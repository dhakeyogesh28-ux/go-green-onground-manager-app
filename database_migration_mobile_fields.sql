-- ============================================
-- Mobile App Data Fields Migration
-- ============================================
-- This migration adds all fields needed by the mobile app
-- to store check-in/check-out data, battery info, charging data, etc.

-- Step 1: Add battery and charging related columns
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS battery_level INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS battery_health INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS last_charge_type TEXT DEFAULT 'AC',
ADD COLUMN IF NOT EXISTS last_charging_type TEXT DEFAULT 'AC';

-- Step 2: Add inspection and inventory columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS daily_checks JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS last_inventory_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_inspection_date DATE,
ADD COLUMN IF NOT EXISTS inventory_photo_count INTEGER DEFAULT 0;

-- Step 3: Add check-in/out tracking columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS is_vehicle_in BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS last_check_in_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_check_out_time TIMESTAMPTZ;

-- Step 4: Add DC charging counter (for DC charge limit enforcement)
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS consecutive_dc_charges INTEGER DEFAULT 0;

-- Step 5: Add service and maintenance tracking
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS last_service_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_service_type TEXT,
ADD COLUMN IF NOT EXISTS service_attention BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS charging_health TEXT DEFAULT 'Good',
ADD COLUMN IF NOT EXISTS to_dos JSONB DEFAULT '[]'::jsonb;

-- Step 6: Add constraints for data integrity
ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_battery_level_check;

ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_battery_level_check 
CHECK (battery_level >= 0 AND battery_level <= 100);

ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_battery_health_check;

ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_battery_health_check 
CHECK (battery_health >= 0 AND battery_health <= 100);

ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_charge_type_check;

ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_charge_type_check 
CHECK (last_charge_type IN ('AC', 'DC', 'ac', 'dc') OR last_charge_type IS NULL);

-- Step 7: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_is_vehicle_in ON crm_vehicles(is_vehicle_in);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_battery_level ON crm_vehicles(battery_level);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_last_inspection_date ON crm_vehicles(last_inspection_date);

-- Step 8: Add comments to document the columns
COMMENT ON COLUMN crm_vehicles.battery_level IS 'Current battery percentage (0-100)';
COMMENT ON COLUMN crm_vehicles.battery_health IS 'Battery health percentage (0-100)';
COMMENT ON COLUMN crm_vehicles.last_charge_type IS 'Last charging type used: AC or DC';
COMMENT ON COLUMN crm_vehicles.last_charging_type IS 'Alternate field for last charging type';
COMMENT ON COLUMN crm_vehicles.daily_checks IS 'JSON object storing daily inspection checklist results';
COMMENT ON COLUMN crm_vehicles.last_inventory_time IS 'Timestamp of last inventory photo capture';
COMMENT ON COLUMN crm_vehicles.last_inspection_date IS 'Date of last inspection';
COMMENT ON COLUMN crm_vehicles.inventory_photo_count IS 'Number of inventory photos captured';
COMMENT ON COLUMN crm_vehicles.is_vehicle_in IS 'Whether vehicle is currently checked in (IN HUB) or checked out';
COMMENT ON COLUMN crm_vehicles.last_check_in_time IS 'Timestamp of last check-in';
COMMENT ON COLUMN crm_vehicles.last_check_out_time IS 'Timestamp of last check-out';
COMMENT ON COLUMN crm_vehicles.consecutive_dc_charges IS 'Counter for consecutive DC fast charges (max 5 before AC required)';
COMMENT ON COLUMN crm_vehicles.service_attention IS 'Whether vehicle needs service attention';
COMMENT ON COLUMN crm_vehicles.charging_health IS 'Overall charging system health status';
COMMENT ON COLUMN crm_vehicles.to_dos IS 'JSON array of pending tasks for this vehicle';

-- ============================================
-- Update existing records with default values
-- ============================================
UPDATE crm_vehicles 
SET 
    battery_level = COALESCE(battery_level, 85),
    battery_health = COALESCE(battery_health, 85),
    last_charge_type = COALESCE(last_charge_type, 'AC'),
    last_charging_type = COALESCE(last_charging_type, 'AC'),
    daily_checks = COALESCE(daily_checks, '{}'::jsonb),
    inventory_photo_count = COALESCE(inventory_photo_count, 0),
    is_vehicle_in = COALESCE(is_vehicle_in, true),
    consecutive_dc_charges = COALESCE(consecutive_dc_charges, 0),
    service_attention = COALESCE(service_attention, false),
    charging_health = COALESCE(charging_health, 'Good'),
    to_dos = COALESCE(to_dos, '[]'::jsonb)
WHERE battery_level IS NULL 
   OR battery_health IS NULL 
   OR last_charge_type IS NULL
   OR daily_checks IS NULL
   OR is_vehicle_in IS NULL;

-- ============================================
-- Create function to update check-in/out timestamps
-- ============================================
CREATE OR REPLACE FUNCTION update_check_in_out_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Update check-in timestamp when vehicle is checked in
    IF NEW.is_vehicle_in = true AND (OLD.is_vehicle_in IS NULL OR OLD.is_vehicle_in = false) THEN
        NEW.last_check_in_time = NOW();
    END IF;
    
    -- Update check-out timestamp when vehicle is checked out
    IF NEW.is_vehicle_in = false AND (OLD.is_vehicle_in IS NULL OR OLD.is_vehicle_in = true) THEN
        NEW.last_check_out_time = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS trg_update_check_in_out_timestamp ON crm_vehicles;
CREATE TRIGGER trg_update_check_in_out_timestamp
    BEFORE UPDATE ON crm_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_check_in_out_timestamp();

-- ============================================
-- RLS (Row Level Security) Policies
-- ============================================
-- Ensure users can update these new columns

DROP POLICY IF EXISTS "Allow authenticated users to update vehicle data" ON crm_vehicles;

CREATE POLICY "Allow authenticated users to update vehicle data"
ON crm_vehicles
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- ============================================
-- Verification Queries
-- ============================================
-- Run these queries to verify the migration was successful:

-- Check if all columns were added successfully
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'crm_vehicles' 
-- AND column_name IN (
--     'battery_level', 'battery_health', 'last_charge_type', 
--     'daily_checks', 'is_vehicle_in', 'consecutive_dc_charges'
-- )
-- ORDER BY column_name;

-- Check constraints
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_name LIKE 'crm_vehicles_%'
-- ORDER BY constraint_name;

-- View sample data
-- SELECT 
--     vehicle_id,
--     registration_number,
--     battery_level,
--     last_charge_type,
--     is_vehicle_in,
--     consecutive_dc_charges,
--     last_inspection_date
-- FROM crm_vehicles
-- LIMIT 5;

-- ============================================
-- Test the migration
-- ============================================
-- Test updating vehicle data (like the mobile app does)
-- UPDATE crm_vehicles 
-- SET 
--     battery_level = 85,
--     last_charge_type = 'AC',
--     is_vehicle_in = false,
--     status = 'active',
--     daily_checks = '{"battery_health": true, "charging_port": true}'::jsonb,
--     last_inventory_time = NOW(),
--     last_inspection_date = CURRENT_DATE
-- WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);

-- Verify the update
-- SELECT * FROM crm_vehicles WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);
