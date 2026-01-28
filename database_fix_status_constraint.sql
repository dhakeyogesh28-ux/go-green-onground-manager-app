-- ============================================
-- QUICK FIX: Update Status Constraint
-- ============================================
-- This script updates the status constraint to include
-- all status values used by the mobile app
-- Run this IMMEDIATELY to fix the check-in/out errors

-- Drop the old constraint
ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_status_check;

-- Add new constraint with all status values
ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN (
    'active',       -- Vehicle checked out / in use
    'inactive',     -- Not in use
    'scrapped',     -- Decommissioned
    'trial',        -- Testing phase
    'charging',     -- Checked in and charging (Mobile App)
    'maintenance',  -- Needs service/repair (Mobile App)
    'idle'          -- Available but not in use (Mobile App)
));

-- Update the column comment
COMMENT ON COLUMN crm_vehicles.status IS 'Vehicle status: active (checked out/in use), inactive (not in use), scrapped (decommissioned), trial (testing), charging (checked in and charging), maintenance (needs service/repair), idle (available but not in use)';

-- Verify the constraint was updated
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'crm_vehicles_status_check';

-- Test: Try to set a vehicle to 'charging' status (should work now)
-- UPDATE crm_vehicles 
-- SET status = 'charging' 
-- WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);
