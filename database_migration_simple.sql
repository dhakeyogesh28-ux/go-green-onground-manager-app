-- ============================================
-- SIMPLE VERSION - Just add status column
-- ============================================
-- Run this in your Supabase SQL Editor

-- Add status column with default value 'idle'
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'idle';

-- Add constraint to allow only valid values
ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN ('active', 'idle', 'charging', 'maintenance'));

-- Update existing records
UPDATE crm_vehicles 
SET status = 'idle' 
WHERE status IS NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_status ON crm_vehicles(status);

-- Done! Now test with:
-- SELECT vehicle_id, registration_number, status FROM crm_vehicles LIMIT 5;
