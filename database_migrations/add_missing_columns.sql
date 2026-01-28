-- Add missing columns to crm_vehicles table
-- Run this in your Supabase SQL Editor

-- Add status column
ALTER TABLE crm_vehicles 
  ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('pending', 'inProgress', 'completed')) DEFAULT 'pending';

-- Add battery_health column
ALTER TABLE crm_vehicles 
  ADD COLUMN IF NOT EXISTS battery_health INTEGER CHECK (battery_health >= 0 AND battery_health <= 100);

-- Add last_charging_type column (if not already added from daily_inspections.sql)
ALTER TABLE crm_vehicles 
  ADD COLUMN IF NOT EXISTS last_charging_type TEXT CHECK (last_charging_type IN ('AC', 'DC'));

-- Add other inspection-related columns (if not already added)
ALTER TABLE crm_vehicles 
  ADD COLUMN IF NOT EXISTS last_inspection_date DATE,
  ADD COLUMN IF NOT EXISTS is_in_servicing BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS servicing_status TEXT CHECK (servicing_status IN ('service_ok', 'attention', 'not_applicable'));

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON crm_vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_last_inspection ON crm_vehicles(last_inspection_date);

-- Update existing vehicles to have default values
UPDATE crm_vehicles 
SET status = 'pending' 
WHERE status IS NULL;

-- Set battery_health to match battery_level for existing vehicles
UPDATE crm_vehicles 
SET battery_health = CAST(battery_level AS INTEGER)
WHERE battery_health IS NULL AND battery_level IS NOT NULL;

-- Set default last_charging_type to 'AC' for existing vehicles
UPDATE crm_vehicles 
SET last_charging_type = 'AC'
WHERE last_charging_type IS NULL;
