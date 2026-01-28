-- ============================================
-- Add driver_remark column to crm_vehicles
-- Run this in Supabase SQL Editor
-- ============================================

-- Add the driver_remark column
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS driver_remark TEXT;

-- Add a helpful comment
COMMENT ON COLUMN crm_vehicles.driver_remark IS 'Remark entered by driver during check-in/check-out inventory';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'crm_vehicles' 
AND column_name = 'driver_remark';
