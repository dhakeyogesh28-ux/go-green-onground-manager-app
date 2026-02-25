-- ============================================
-- Charging Counter Migration
-- ============================================
-- This migration adds the ac_charge_count column to the crm_vehicles table.
-- It also handles data cleanup and documentation.

-- 1. Add the column
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS ac_charge_count INTEGER DEFAULT 0;

-- 2. Update existing records with default value
UPDATE crm_vehicles 
SET ac_charge_count = 0 
WHERE ac_charge_count IS NULL;

-- 3. Add comment to document the column
COMMENT ON COLUMN crm_vehicles.ac_charge_count IS 'Counter for AC charges. A mandatory DC charge is required every 6 AC charges to reset this counter.';

-- 4. Clean up old column (Optional/Caution: Make sure it's not used by other apps)
-- ALTER TABLE crm_vehicles DROP COLUMN IF EXISTS consecutive_dc_charges;

-- 5. Verification
-- SELECT registration_number, ac_charge_count FROM crm_vehicles LIMIT 10;
